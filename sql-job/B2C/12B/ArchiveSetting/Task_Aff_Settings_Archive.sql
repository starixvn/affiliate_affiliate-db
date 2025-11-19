/*<info serverAlias="DBAFF12B-Affiliate_12B" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_Settings_Archive]
	@MonthDate SMALLDATETIME
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Job - Archive Setting

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250324@Sally: Remove P2P Settings [RedmineID: #219936]
		- 20250526@Lewis: Apply FromDate - ToDate [RedmineID: #228530]
		- 20251027@Lewis: Apply IsSubCommRate [RedmineID: #235601]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @NextMonthDate SMALLDATETIME
	DECLARE @ToDate DATETIME = '9999-12-31'

	SELECT  @MonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
	SELECT  @NextMonthDate	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 2, 0))


	IF (
		EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate))
		OR EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate))
	)
	BEGIN
		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate)
		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate)
		DELETE dbo.CommGroupHistory WITH(ROWLOCK, UPDLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate)
	END

	-- Archive settings
	BEGIN
		INSERT INTO dbo.TierSettingHistory (GroupId,GroupProductId,TierId,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission,IsActivePlayerSum)
		SELECT GroupId,GroupProductId,TierId,@MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission,IsActivePlayerSum
		FROM dbo.TierSetting t WITH (NOLOCK)

		INSERT INTO dbo.TierSettingHistory (GroupId,GroupProductId,TierId,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission,IsActivePlayerSum)
		SELECT GroupId,GroupProductId,TierId,@NextMonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission,IsActivePlayerSum
		FROM dbo.TierSetting WITH (NOLOCK)

		--AffGroupHistory
		--old
		UPDATE a SET a.ToDate = @MonthDate
		FROM dbo.AffGroupHistory a WITH (ROWLOCK,UPDLOCK)
		WHERE ISNULL(GroupId, 0) > 0 AND a.ToDate = @ToDate AND a.Monthdate = @MonthDate
		
		--new
		--delete next month if any
		DELETE FROM dbo.AffGroupHistory
		WHERE MonthDate = @NextMonthDate
			AND ISNULL(GroupId, 0) > 0
			AND ToDate = @ToDate
		
		--insert new from AffInfo for nextmonth
		INSERT INTO dbo.AffGroupHistory (AffId,MonthDate,GroupId,ParentAffId,AllParentAffId,FromDate,ToDate)
		SELECT AffId,@NextMonthDate,GroupId,ParentAffId,AllParentAffId,DATEADD(MONTH, DATEDIFF(MONTH, 0, @NextMonthDate), 0),@ToDate
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ISNULL(GroupId, 0) > 0

		INSERT INTO dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
		SELECT GroupId,@MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		FROM dbo.DeductionSetting ds WITH (NOLOCK)

		INSERT INTO dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
		SELECT GroupId,@NextMonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		FROM dbo.DeductionSetting ds WITH (NOLOCK)

		;WITH CTE_MonthDate AS
		(
			SELECT @MonthDate AS MonthDate
			UNION ALL
			SELECT @NextMonthDate
		)
		INSERT INTO dbo.CommGroupHistory (GroupId, MonthDate, SubCommRate, QMTurnover, IsSubCommRate)
		SELECT GroupId, e.MonthDate, SubCommRate, QMTurnover, IsSubCommRate
		FROM dbo.CommGroup WITH(NOLOCK)
			CROSS JOIN CTE_MonthDate e 
	END
END
GO