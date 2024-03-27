/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
/*
	Created: 20240311@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: 
	Step 3
		- ReCalculate monthly commission 2024-02
		
*/  

DECLARE @WinlostDate SMALLDATETIME = '2024-02-10'
EXEC Task_Aff_Monthly_Commission @MonthDate = @WinlostDate, @IsForceUpdate = 1;
GO
