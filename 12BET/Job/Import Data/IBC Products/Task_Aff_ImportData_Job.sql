/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_Job]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Import data of IBC's Products from bettrans (MoveBetsDay + 1 to yesterday)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @Retry TINYINT = 1, @MaxRetry TINYINT = 3, @IsErr BIT, @ErrMsg NVARCHAR(2000)
	
	DECLARE @MoveBetsDay SMALLDATETIME, @CurrentDate SMALLDATETIME, @WinlostDate SMALLDATETIME

	DECLARE @MBBUDate TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBUDate (BalanceUpDay, MoveBetsDay)
	EXEC DBEXT.bodb02.dbo.Lrf_SelBalanceUpDay

	SELECT @MoveBetsDay = MoveBetsDay FROM @MBBUDate
	SELECT @WinlostDate = DATEADD(DAY, 1, @MoveBetsDay)
	SELECT @CurrentDate = CONVERT(DATE, GETDATE())

	WHILE @WinlostDate < @CurrentDate
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
				PRINT 'Failed to generate data for MemberDaily/AffDaily/AffDailySummary on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CONVERT(VARCHAR(10), @Retry)
				
				SELECT @Retry = @Retry + 1
				
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END

		IF @IsErr = 1
		BEGIN
			SELECT @ErrMsg = 'Failed to generate data for MemberDaily/AffDaily/AffDailySummary on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
			RAISERROR (@ErrMsg, 16, 1)
		END

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END
END
GO