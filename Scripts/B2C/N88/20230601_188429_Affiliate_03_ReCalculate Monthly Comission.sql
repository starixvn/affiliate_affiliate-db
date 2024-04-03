/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
/*
	Created: 20230601@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: 
	Step 7
		- ReCalculate monthly commission 04
		- Update data DeductionSetting of Operational Fee = 0 
		
*/  
--1. ReCalculate monthly commission 04
DECLARE @WinlostDate SMALLDATETIME = '2023-04-27'
EXEC Task_Aff_Monthly_Commission @MonthDate = @WinlostDate, @IsForceUpdate = 1;
WAITFOR DELAY '000:00:00.280'
GO

UPDATE r SET r.DeductedPercentage = 0
FROM  dbo.DeductionSetting r WITH (ROWLOCK)
WHERE DeductionId = 11
	AND DeductedPercentage <>0