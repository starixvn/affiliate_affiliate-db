/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250918@Sally	
	Task: Rerun ImportData of player
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250922@Sally: Created [RedmineID: #238812]

*/
USE Affiliate_12B
GO

DECLARE @FromDate DATE = '2025-09-01'
		,@ToDate DATE = CAST(DATEADD(HOUR, 8, GETUTCDATE()) AS DATE)
		,@ErrorMsg NVARCHAR(MAX)

WHILE @FromDate <= @ToDate
BEGIN

	BEGIN TRY
	--exec SP
		EXEC Task_Aff_ImportData @WinlostDate = @FromDate
		PRINT 'Success: ' + CAST(@FromDate AS VARCHAR(10))
    END TRY
	BEGIN CATCH
		SELECT @ErrorMsg = ERROR_MESSAGE()
		PRINT 'Failed: ' + CAST(@FromDate AS VARCHAR(10)) + ' - ' + @ErrorMsg 
	END CATCH

	SET @FromDate = DATEADD(DAY, 1, @FromDate)
	WAITFOR DELAY '00:00:00.280'
END