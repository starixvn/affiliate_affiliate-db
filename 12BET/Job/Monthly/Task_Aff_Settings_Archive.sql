/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_Settings_Archive]
	@MonthDate		SMALLDATETIME,
	@IsForceUpdate	BIT = 0
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Affiliate 12BET - Job - Archive Setting

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

	SELECT  @FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

	-- Archive Setting
	IF (
		EXISTS (SELECT 1 FROM dbo.CommGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
	)
	BEGIN
		DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = @LastDayOfMonth
		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = @LastDayOfMonth
		DELETE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = @LastDayOfMonth
		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = @LastDayOfMonth
	END

	-- Archive settings
	BEGIN
		INSERT INTO dbo.CommGroupHistory (GroupID,MonthDate,GroupName,CreatedDate,Creator,IsDeleted,Description,QMTurnover)
		SELECT GroupID,@LastDayOfMonth,GroupName,CreatedDate,Creator,IsDeleted,Description,QMTurnover
		FROM dbo.CommGroup WITH (NOLOCK)

		INSERT INTO dbo.TierSettingHistory (GroupID,TierID,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT GroupID,TierID,@LastDayOfMonth,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM dbo.TierSetting WITH (NOLOCK)

		INSERT INTO dbo.AffGroupHistory (AffID,MonthDate,GroupID)
		SELECT AffID,@LastDayOfMonth,GroupID
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ISNULL(GroupID, 0) > 0

		INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage,ProductId)
		SELECT GroupID,@LastDayOfMonth,DeductionID,DeductedPercentage,ProductId
		FROM dbo.DeductionSetting ds WITH (NOLOCK)

		-- Apply next value
		BEGIN
			DELETE dbo.DeductionSetting WITH(ROWLOCK, UPDLOCK)
			WHERE DeductionID = 9 AND NextDeductedPercentage IS NULL

			UPDATE dbo.DeductionSetting WITH(ROWLOCK, UPDLOCK)
			SET DeductedPercentage = NextDeductedPercentage, GroupProductId = NextGroupProductId
			WHERE DeductionID IN (9, 10, 11, 12)

			UPDATE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
			SET QMTurnover = NextQMTurnover
		END
	END
END
GO