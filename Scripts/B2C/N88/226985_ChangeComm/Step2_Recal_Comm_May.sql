/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250605@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: 
	Step 2
		- ReCalculate monthly commission 
	USE Affiliate_N88
	GO
	USE Affiliate_N8B
	GO
	USE Affiliate_N8G
	GO
*/  

DECLARE @WinlostDate SMALLDATETIME = '2025-05-27'

EXEC Task_Aff_Monthly_Commission @MonthDate = @WinlostDate, @IsForceUpdate = 1;
GO