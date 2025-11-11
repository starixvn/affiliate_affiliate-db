/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251111@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Reproduct CPA 15-07 [RedmineID: #242980]
*/

/*
run job 15/07 - currentDate
*/

USE Affiliate_12B

DECLARE @CPADate DATE = '2025-07-15'
		,@CurrentDate DATE = CAST(DATEADD(HOUR, 12, GETDATE()) AS DATE)
		,@ErrorMsg NVARCHAR(MAX)

WHILE @CPADate <= @CurrentDate
BEGIN

	BEGIN TRY
	--exec job
		EXEC Task_Aff_CPACalculation_Job @Step = 0, @Date = @CPADate
		PRINT 'Success: ' + CAST(@CPADate AS VARCHAR(10))
    END TRY
	BEGIN CATCH
		SELECT @ErrorMsg = ERROR_MESSAGE()
		PRINT 'Failed: ' + CAST(@CPADate AS VARCHAR(10)) + ' - ' + @ErrorMsg 
	END CATCH

	SET @CPADate = DATEADD(DAY, 1, @CPADate)
	WAITFOR DELAY '00:00:00.280'
END