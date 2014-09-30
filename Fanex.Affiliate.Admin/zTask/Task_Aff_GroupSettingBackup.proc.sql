ALTER PROCEDURE [dbo].[Task_Aff_GroupSettingBackup] 
	@Month INT
	,@Year INT
AS
/*
Created: 20090812@DungTong
Task : Backup all group settings monthly on last day of selected month
DB: DB052.Affiliate_MYM
Original:

Revisions:                     

Param's Explanation:
• @Month: The month to transfer
• @Year :  The year to transfer     
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME

	SELECT @FirstDay 	= CAST(CAST(@Year AS VARCHAR(5)) + '-' + CAST(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)
		,@LastDay 		= DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))

	IF (DATEDIFF(d, CURRENT_TIMESTAMP, @LastDay) > 0)
	BEGIN
		SELECT 'The month is not completed yet. So you cannot backup data!' Result

		SELECT @FirstDay AS FirstDay
			,@LastDay AS LastDay

		RETURN
	END

	--Check group History data is inserted
	IF (
			EXISTS (
				SELECT TOP (1) 1
				FROM dbo.CommGroupHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			OR EXISTS (
				SELECT TOP (1) 1
				FROM dbo.GroupSettingHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			OR EXISTS (
				SELECT TOP (1) 1
				FROM dbo.DeductionSettingHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			OR EXISTS (
				SELECT TOP (1) 1
				FROM dbo.AffGroupHistory(NOLOCK)
				WHERE monthdate = @LastDay
				)
			)
	BEGIN
		DELETE dbo.CommGroupHistory
		WHERE monthdate = @LastDay

		DELETE dbo.GroupSettingHistory
		WHERE monthdate = @LastDay

		DELETE dbo.DeductionSettingHistory
		WHERE monthdate = @LastDay

		DELETE dbo.AffGroupHistory
		WHERE monthdate = @LastDay
	END

	INSERT INTO dbo.[CommGroupHistory] (
		[GroupID]
		,[MonthDate]
		,[GroupName]
		,[CreatedDate]
		,[Creator]
		,[IsDeleted]
		,[Description]
		,[QualifiedAmount]
		,[Currency]
		,[DepositPercent]
		,[WithdrawalPercent]
		)
	SELECT GroupID
		,@LastDay
		,[GroupName]
		,[CreatedDate]
		,[Creator]
		,[IsDeleted]
		,[Description]
		,[QualifiedAmount]
		,[Currency]
		,[DepositPercent]
		,[WithdrawalPercent]
	FROM dbo.CommGroup(NOLOCK)

	INSERT INTO dbo.GroupSettingHistory (
		[GroupID]
		,[ProductID]
		,[TierID]
		,[MonthDate]
		,[MinAmount]
		,[MaxAmount]
		,[MinQM]
		,[MaxQM]
		,[Commission]
		)
	SELECT GroupID
		,ProductID
		,TierID
		,@LastDay
		,MinAmount
		,MaxAmount
		,MinQM
		,MaxQM
		,Commission
	FROM dbo.GroupSetting(NOLOCK)

	INSERT INTO dbo.DeductionSettingHistory (
		GroupID
		,MonthDate
		,DeductionID
		,DeductedPercentage
		)
	SELECT GroupID
		,@LastDay
		,DeductionID
		,DeductedPercentage
	FROM dbo.DeductionSetting(NOLOCK)

	INSERT INTO dbo.AffGroupHistory (
		AffID
		,MonthDate
		,GroupID
		)
	SELECT AffID
		,@LastDay
		,GroupID
	FROM dbo.AffInfo(NOLOCK)
	WHERE GroupID IS NOT NULL
		AND GroupID > 0

	DECLARE @TaskID INT
		,@LogID INT
		,@RunDate DATETIME
		,@Status VARCHAR(50)

	SELECT @RunDate = getdate()
		,@Status = 'completed'

	SELECT @TaskID = TaskID
	FROM dbo.TaskManager(NOLOCK)
	WHERE TaskName = 'Backup Commission Group'

	EXEC [dbo].[Aff_TaskLogIns] @TaskID
		,@RunDate
		,@Status
		,@LogID OUTPUT
END
GO


