/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_Process]
	@ProductId		INT,
	@QueueIdInput	INT = 0, -- manually import
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse xml data from Queue by Product

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @QueueId BIGINT, @XmlData XML, @WinlostDate SMALLDATETIME

	CREATE TABLE #Betsoft (Username NVARCHAR(50), GameSessionId BIGINT, GameId INT, PlatForm VARCHAR(50), BetId INT, Amount MONEY, Win MONEY, BetTime DATETIME)

	-- Manually import
	IF @QueueIdInput <> 0
		SELECT @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND QueueId = @QueueIdInput
	ELSE
		SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND FinishedTime IS NULL
		ORDER BY QueueId

	WHILE @XmlData IS NOT NULL
	BEGIN
		-- clean up tmp table
		TRUNCATE TABLE #Betsoft

		-- Ebet
		IF @ProductId = 10
		BEGIN
			RETURN
		END
		-- Betsoft
		ELSE IF @ProductId = 11
		BEGIN
			BEGIN TRY
				INSERT INTO #Betsoft (Username, GameSessionId, GameId, PlatForm, BetId, Amount, Win, BetTime)
				SELECT	t.c.value('(USERNAME/text())[1]', 'NVARCHAR(50)')				AS Username,
						t.c.value('(GAMESESSION/@id)[1]', 'BIGINT')						AS GameSessionId,
						t.c.value('(GAMESESSION/GAMEID/text())[1]', 'INT')				AS GameId,
						t.c.value('(GAMESESSION/PLATFORM/text())[1]', 'VARCHAR(50)')	AS PlatForm,
						t1.c.value('@id', 'INT')										AS BetId,
						t1.c.value('(AMOUNT/text())[1]', 'MONEY')						AS Amount,
						t1.c.value('(WIN/text())[1]', 'MONEY')							AS Win,
						t1.c.value('(BETTIME/text())[1]', 'DATETIME')					AS BetTime
				FROM @XmlData.nodes('BSGSYSTEM/RESPONSE/ACCOUNT') AS t(c)
					CROSS APPLY t.c.nodes('GAMESESSION/BET') AS t1(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				DELETE bb WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_Betsoft bb
				WHERE EXISTS (SELECT 1 FROM #Betsoft b WHERE bb.Username = b.Username AND bb.GameSessionId = b.GameSessionId AND bb.GameId = b.GameId)

				INSERT INTO dbo.bettrans_Betsoft (IBCCustId, Username, GameSessionId, GameId, PlatForm, BetId, Amount, Win, BetTime, WinlostDate)
				SELECT m.IBCCustId, b.Username, b.GameSessionId, b.GameId, b.PlatForm, b.BetId, b.Amount, b.Win, b.BetTime, CONVERT(DATE, b.Bettime) AS WinlostDate
				FROM #Betsoft b
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + b.Username = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, BetTime)) FROM #Betsoft
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = GETDATE(), WinlostDate = @WinlostDate, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END

		UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
		SET FinishedTime = GETDATE(), WinlostDate = @WinlostDate, LogDesc = 'Successfully'
		WHERE QueueId = @QueueId

		SELECT @QueueId = NULL, @XmlData = NULL

		SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND FinishedTime IS NULL
		ORDER BY QueueId
	END

	DROP TABLE #Betsoft
END
GO