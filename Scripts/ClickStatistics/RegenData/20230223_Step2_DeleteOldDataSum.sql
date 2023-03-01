/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/

/*
	Created: 20230223@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Regen data [RedmineID: #177639]

*/

DECLARE @DateSum TABLE (Id INT IDENTITY(1, 1), WinlostDate DATE PRIMARY KEY)
INSERT INTO @DateSum (WinlostDate)
VALUES ('2018-01-18'), ('2017-12-22'), ('2017-06-22'), ('2015-05-28')

DECLARE @WinlostDate DATETIME, @Id INT = 1

WHILE 1 = 1
BEGIN
	SELECT @WinlostDate = WinlostDate FROM @DateSum WHERE Id = @Id
	IF @@ROWCOUNT = 0
		BREAK

	WHILE 1 = 1 
	BEGIN
		DELETE TOP(1000) d WITH(ROWLOCK, UPDLOCK)
		FROM ClickStatisticsSum_Country_Domain d
		WHERE d.Date = @WinlostDate

		IF @@ROWCOUNT = 0
			BREAK
	END

	WHILE 1 = 1
	BEGIN
		DELETE TOP(1000) d WITH(ROWLOCK, UPDLOCK)
		FROM ClickStatisticsSum_Country_Sport d
		WHERE d.Date = @WinlostDate

		IF @@ROWCOUNT = 0
			BREAK
	END

	WHILE 1 = 1
	BEGIN
		DELETE TOP(1000) d WITH(ROWLOCK, UPDLOCK)
		FROM ClickStatisticsSum_Sport_Language d
		WHERE d.Date = @WinlostDate

		IF @@ROWCOUNT = 0
			BREAK
	END

	WHILE 1 = 1
	BEGIN
		DELETE TOP(1000) d WITH(ROWLOCK, UPDLOCK)
		FROM ClickStatistics1Sum d
		WHERE d.Date = @WinlostDate

		IF @@ROWCOUNT = 0
			BREAK
	END

	PRINT 'Deleted data on : ' + CONVERT(VARCHAR(100),  @WinlostDate, 120)

	SET @Id += 1
END

--Sum

