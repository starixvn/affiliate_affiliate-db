/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220920@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Delete data for ClickStatistics1Sum since 01/Aug/2020 [RedmineId : #176390]
*/

DECLARE @BeginRegenData SMALLDATETIME = CONVERT(SMALLDATETIME, '2020-08-01') --Regen data country since 01/Aug/2020

WHILE 1 = 1
BEGIN
	DELETE TOP(2000) dbo.ClickStatistics1Sum WITH (ROWLOCK, UPDLOCK)
	WHERE Date >= @BeginRegenData
	
	IF @@ROWCOUNT < 2000
		BREAK
END

