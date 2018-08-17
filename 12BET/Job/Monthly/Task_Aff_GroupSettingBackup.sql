/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_GroupSettingBackup]
	@Month	INT,
	@Year	INT
AS

/*
	Created: 20090812@DungTong
	Task: Backup all group settings monthly on last day of selected month
	DB: DBAFF12BET.Affiliate_12BET
	Original:

	Revisions:		           
		- 20170525@Percy: Apply Cash Out Win Loss Share [RedmineID: #74874]
		- 20180601@Percy: Flexible new settings [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDay SMALLDATETIME, @LastDay SMALLDATETIME

	SELECT  @FirstDay	= CONVERT(SMALLDATETIME, CONVERT(VARCHAR(4), @Year) + '-' + CONVERT(VARCHAR(2), @Month) + '-' + '1')
	SELECT  @LastDay	= DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDay))

	IF @LastDay > CONVERT(DATE, GETDATE())
	BEGIN
		SELECT 'The month is not completed yet. So you cannot backup data!' Result
		SELECT @FirstDay AS FirstDay, @LastDay AS LastDay
		
		RETURN
	END

	-- Check group History data is inserted
	IF (
		EXISTS (SELECT 1 FROM dbo.CommGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDay)
		OR EXISTS (SELECT 1 FROM dbo.GroupSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDay)
		OR EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDay)
		OR EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDay)
	)
	BEGIN
		DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = @LastDay
		DELETE dbo.GroupSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = @LastDay
		DELETE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate = @LastDay

		DELETE ds WITH (ROWLOCK, UPDLOCK)
		FROM dbo.DeductionSettingHistory ds
			INNER JOIN dbo.DeductionType dt WITH (NOLOCK) ON ds.DeductionID = dt.DTypeID
		WHERE ds.MonthDate = @LastDay
	END

	-- Archive settings
	BEGIN
		INSERT INTO dbo.CommGroupHistory (GroupID,MonthDate,GroupName,CreatedDate,Creator,IsDeleted,Description,QMTurnover)
		SELECT GroupID,@LastDay,GroupName,CreatedDate,Creator,IsDeleted,Description,QMTurnover
		FROM dbo.CommGroup WITH (NOLOCK)

		INSERT INTO dbo.GroupSettingHistory (GroupID,SportType,TierID,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT GroupID,SportType,TierID,@LastDay,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM dbo.GroupSetting WITH (NOLOCK)

		INSERT INTO dbo.AffGroupHistory (AffID,MonthDate,GroupID)
		SELECT AffID,@LastDay,GroupID
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ISNULL(GroupID, 0) > 0

		INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage)
		SELECT ds.GroupID,@LastDay,ds.DeductionID,ds.DeductedPercentage
		FROM dbo.DeductionSetting ds WITH (NOLOCK)
			INNER JOIN dbo.DeductionType dt WITH (NOLOCK) ON ds.DeductionID = dt.DTypeID

		-- For Cash Out WL Share
		BEGIN
			DELETE dbo.DeductionSetting WITH(ROWLOCK, UPDLOCK)
			WHERE DeductionID = 9 AND NextDeductedPercentage IS NULL

			UPDATE dbo.DeductionSetting WITH(ROWLOCK, UPDLOCK)
			SET DeductedPercentage = NextDeductedPercentage
			WHERE DeductionID = 9
		END
	END
END
GO