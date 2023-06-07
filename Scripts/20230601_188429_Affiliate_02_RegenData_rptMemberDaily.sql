/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
/*
	Created: 20230601@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: 
	Step 6
		- EXEC Job pull data dbo.TpExchange 
		- Regen data 2023-05, 2023-04 into rptMemberDaily		
*/  
--1. EXEC Job pull data dbo.TpExchange 
EXEC [dbo].[Task_ExchangeOanda_Import]
GO
--2. Regen data 2023-05, 2023-04 into rptMemberDaily	
DECLARE	@FromDate   SMALLDATETIME = '2023-04-01'
		,@ToDate		SMALLDATETIME = '2023-05-31'
		,@WinlostDate	SMALLDATETIME

	SELECT @WinlostDate = @FromDate
	WHILE  (@WinlostDate <= @ToDate)
	BEGIN
		BEGIN
			EXEC Task_Aff_ImportData @WinlostDate = @WinlostDate
		END	
		PRINT @WinlostDate
		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
		WAITFOR DELAY '000:00:00.280'
	END

GO
--NOTE: After execute this script, notify to DBA to checking data