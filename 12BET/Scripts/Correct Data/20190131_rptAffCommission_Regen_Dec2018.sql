USE [Affiliate_12BET]
GO

/*
	Created: 20190131@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Regen commission data of Dec 2018
*/

EXEC dbo.Task_Aff_Monthly_Commission @MonthDate = '2018-12-31', @IsForceUpdate = 1