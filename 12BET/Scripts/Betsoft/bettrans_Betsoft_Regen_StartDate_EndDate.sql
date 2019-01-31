USE [Affiliate_12BET]
GO

/*
	Created: 20190128@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Regen data for 2 new columns: StartDate, EndDate
*/

DECLARE @QueueId BIGINT, @XmlData XML, @LatestQueueId BIGINT = 0

DECLARE @StartDate DATETIME, @EndDate DATETIME, @WinlostDate SMALLDATETIME

DECLARE @i INT = 0

CREATE TABLE #Betsoft (Username NVARCHAR(50), GameSessionId BIGINT, StartDate DATETIME, EndDate DATETIME)

WHILE 1 = 1
BEGIN
	DELETE #Betsoft

	SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
	WHERE ProductId = 11 AND JobType = 0 AND CheckInTime >= '2018-12-01' AND QueueId > @LatestQueueId

	IF @@ROWCOUNT = 0
		BREAK;

	SELECT @LatestQueueId = @QueueId

	BEGIN TRY
		SELECT	@StartDate = REPLACE(t.c.value('(STARTDATE/text())[1]', 'VARCHAR(50)'), '_', ' '),
				@EndDate = REPLACE(t.c.value('(ENDDATE/text())[1]', 'VARCHAR(50)'), '_', ' ')
		FROM @XmlData.nodes('BSGSYSTEM/REQUEST') AS t(c)

		-- Convert from GMT+0 to GMT-4
		SELECT @StartDate = DATEADD(HOUR, -4, @StartDate), @EndDate = DATEADD(HOUR, -4, @EndDate)

		IF DATEDIFF(DAY, @StartDate, DATEADD(SECOND, -1, @EndDate)) <> 0
		BEGIN
			SELECT 'QueueId = ' + CONVERT(NVARCHAR(100), @QueueId) + ': StartDate and EndDate are not in the same date!'
			RETURN
		END

		SELECT @WinlostDate = CONVERT(DATE, @StartDate)
				
		INSERT INTO #Betsoft (Username, GameSessionId, StartDate, EndDate)
		SELECT	t.c.value('(USERNAME/text())[1]', 'NVARCHAR(50)')	AS Username,
				t1.c.value('@id', 'BIGINT')							AS GameSessionId,
				@StartDate,
				@EndDate
		FROM @XmlData.nodes('BSGSYSTEM/RESPONSE/ACCOUNT') AS t(c)
			CROSS APPLY t.c.nodes('GAMESESSION') AS t1(c)
		OPTION (OPTIMIZE FOR (@XmlData = NULL))

		UPDATE bb WITH (ROWLOCK, UPDLOCK)
		SET bb.StartDate = @StartDate,
			bb.EndDate = @EndDate,
			bb.WinlostDate = @WinlostDate
		FROM dbo.bettrans_Betsoft bb
			INNER JOIN #Betsoft b ON bb.Username = b.Username AND bb.GameSessionId = b.GameSessionId
	END TRY
	BEGIN CATCH
		SELECT 'QueueId = ' + CONVERT(VARCHAR(20), @QueueId) + ': ' + ERROR_MESSAGE()

		RETURN
	END CATCH

	SELECT @QueueId AS QueueId

	SELECT @i = @i + 1

	IF @i%50 = 0
		WAITFOR DELAY '00:00:05.000'

END

DROP TABLE #Betsoft