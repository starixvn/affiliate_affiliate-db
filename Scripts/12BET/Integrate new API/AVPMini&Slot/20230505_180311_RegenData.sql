/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230505@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Run job again  [RedmineId : #180311]

*/
EXEC dbo.Task_Aff_Monthly_Commission @MonthDate = '2023-04-05', @IsForceUpdate = 1
GO