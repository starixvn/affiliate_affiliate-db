/*<info serverAlias="DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_Job]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Job - Import data of IBC's Products from bettrans

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @Retry TINYINT = 1, @MaxRetry TINYINT = 3, @IsErr BIT, @ErrMsg NVARCHAR(2000)
	
	DECLARE @MoveBetsDay SMALLDATETIME, @CurrentDate SMALLDATETIME, @WinlostDate SMALLDATETIME

	SELECT @MoveBetsDay = MAX(eventdate) FROM bodb02.dbo.match14 WITH (NOLOCK)
	SELECT @WinlostDate = DATEADD(DAY, 1, @MoveBetsDay)
	SELECT @CurrentDate = CONVERT(DATE, GETDATE())

	WHILE @WinlostDate <= @CurrentDate
	BEGIN
		SELECT @Retry = 1, @IsErr = 1
		
		WHILE @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_Aff_ImportData @WinlostDate = @WinlostDate
				
				SELECT @IsErr = 0
				
				BREAK
			END TRY
			BEGIN CATCH
				SELECT @Retry = @Retry + 1
				
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END

		IF @IsErr = 1
		BEGIN
			SELECT @ErrMsg = 'SQL Server Job System: ''Affiliate_N8G: Generate Data Daily'' failed on' + @@SERVERNAME
							+ ' with @WinlostDate = ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
			RAISERROR (@ErrMsg, 16, 1)
		END

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END
END
GO