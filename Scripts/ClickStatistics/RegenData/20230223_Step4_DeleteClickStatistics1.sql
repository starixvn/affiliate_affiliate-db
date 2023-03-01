/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/

/*
	Created: 20230223@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Regen data [RedmineID: #177639]

*/

WHILE 1 = 1 
BEGIN
	DELETE TOP(1000) c WITH(ROWLOCK, UPDLOCK)
	FROM dbo.ClickStatistics1 c
	WHERE c.Date < '2023-02-01'

	IF @@RowCount = 0
		BREAK
END