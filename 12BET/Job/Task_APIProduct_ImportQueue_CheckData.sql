/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_CheckData]
	@ProductId		INT,
	@QueueIdInput	INT = 0, -- manually import
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse xml data from Queue by Product to check Data

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @QueueId BIGINT, @XmlData XML, @WinlostDate SMALLDATETIME, @ListQueueId VARCHAR(MAX) = ''

	CREATE TABLE #Ebet (Username NVARCHAR(50), BetHistoryId NVARCHAR(100), Bet MONEY, Payout MONEY, PayoutTime DATETIME)
	CREATE TABLE #Betsoft (Username NVARCHAR(50), GameSessionId BIGINT, GameId INT, PlatForm VARCHAR(50), BetId INT, Amount MONEY, Win MONEY, BetTime DATETIME)

	-- Manually import
	IF @QueueIdInput <> 0
		SELECT @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND JobType = 1 AND QueueId = @QueueIdInput
	ELSE
		SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
		FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
		WHERE ProductId = @ProductId AND JobType = 1 AND FinishedTime IS NULL
		ORDER BY QueueId

	DECLARE @IsErr BIT = 1
	
	WHILE @XmlData IS NOT NULL
	BEGIN
		-- clean up tmp table
		TRUNCATE TABLE #Ebet
		TRUNCATE TABLE #Betsoft

		-- Ebet
		IF @ProductId = 10
		BEGIN
			BEGIN TRY
				INSERT INTO #Ebet (Username, BetHistoryId, Bet, Payout, PayoutTime)
				SELECT	t.c.value('@USERNAME', 'NVARCHAR(50)')	AS Username,
						t.c.value('@ID', 'NVARCHAR(100)')		AS BetHistoryId,
						t.c.value('@BET', 'MONEY')				AS Bet,
						t.c.value('@PAYOUT', 'MONEY')			AS Payout,
						t.c.value('@PAYOUTTIME', 'DATETIME')	AS PayoutTime
				FROM @XmlData.nodes('ROOT/RESPONSE/BETHISTORYLIST/BETHISTORY') AS t(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				IF EXISTS (
					SELECT 1
					FROM (
						SELECT m.IBCCustId, e.Username, e.BetHistoryId, e.Bet, e.Payout, e.PayoutTime
						FROM #Ebet e
							INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + e.Username = m.Username
					) AS e
						LEFT JOIN dbo.bettrans_Ebet be WITH (NOLOCK) ON e.BetHistoryId = be.BetHistoryId
					WHERE be.BetHistoryId IS NULL
						OR e.Username	<> be.Username
						OR e.Bet		<> be.Bet
						OR e.Payout		<> be.Payout
						OR e.PayoutTime	<> be.PayoutTime
				)
					SELECT @ListQueueId = @ListQueueId + ',' + CONVERT(VARCHAR(20), @QueueId)

				SELECT @WinlostDate = MIN(CONVERT(DATE, PayoutTime)) FROM #Ebet

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END
		-- Betsoft
		ELSE IF @ProductId = 11
		BEGIN
			BEGIN TRY
				INSERT INTO #Betsoft (Username, GameSessionId, GameId, PlatForm, BetId, Amount, Win, BetTime)
				SELECT	t.c.value('(USERNAME/text())[1]', 'NVARCHAR(50)')	AS Username,
						t1.c.value('@id', 'BIGINT')							AS GameSessionId,
						t1.c.value('(GAMEID/text())[1]', 'INT')				AS GameId,
						t1.c.value('(PLATFORM/text())[1]', 'VARCHAR(50)')	AS PlatForm,
						t2.c.value('@id', 'INT')							AS BetId,
						t2.c.value('(AMOUNT/text())[1]', 'MONEY')			AS Amount,
						t2.c.value('(WIN/text())[1]', 'MONEY')				AS Win,
						t2.c.value('(BETTIME/text())[1]', 'DATETIME')		AS BetTime
				FROM @XmlData.nodes('BSGSYSTEM/RESPONSE/ACCOUNT') AS t(c)
					CROSS APPLY t.c.nodes('GAMESESSION') AS t1(c)
					CROSS APPLY t1.c.nodes('BET') AS t2(c)
				OPTION (OPTIMIZE FOR (@XmlData = NULL))

				IF EXISTS (
					SELECT 1
					FROM (
						SELECT m.IBCCustId, b.Username, b.GameSessionId, b.GameId, b.PlatForm, b.BetId, b.Amount, b.Win, b.BetTime
						FROM #Betsoft b
							INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + b.Username = m.Username
					) AS b
						LEFT JOIN dbo.bettrans_Betsoft bb WITH (NOLOCK) ON b.IBCCustId = bb.IBCCustId AND b.GameSessionId = bb.GameSessionId AND b.GameId = bb.GameId AND b.BetId = bb.BetId
					WHERE bb.Username IS NULL
						OR b.PlatForm	<> bb.PlatForm
						OR b.Amount		<> bb.Amount
						OR b.Win		<> bb.Win
						OR b.BetTime	<> bb.BetTime
				)
					SELECT @ListQueueId = @ListQueueId + ',' + CONVERT(VARCHAR(20), @QueueId)
				
				DELETE bb WITH (ROWLOCK, UPDLOCK)
				FROM dbo.bettrans_Betsoft bb
				WHERE EXISTS (SELECT 1 FROM #Betsoft b WHERE bb.Username = b.Username AND bb.GameSessionId = b.GameSessionId AND bb.GameId = b.GameId)
				
				INSERT INTO dbo.bettrans_Betsoft (IBCCustId, Username, GameSessionId, GameId, PlatForm, BetId, Amount, Win, BetTime, WinlostDate)
				SELECT m.IBCCustId, b.Username, b.GameSessionId, b.GameId, b.PlatForm, b.BetId, b.Amount, b.Win, b.BetTime, CONVERT(DATE, b.Bettime) AS WinlostDate
				FROM #Betsoft b
					INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON '12BET$' + b.Username = m.Username

				SELECT @WinlostDate = MIN(CONVERT(DATE, BetTime)) FROM #Betsoft

				SELECT @IsErr = 0
			END TRY
			BEGIN CATCH
				UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = 'Failed. Error Message = ' + ERROR_MESSAGE()
				WHERE QueueId = @QueueId
			END CATCH
		END

		IF @IsErr = 1
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = CONVERT (NVARCHAR(100), @QueueId)
			RETURN
		END
		ELSE
		BEGIN
			UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
			SET FinishedTime = GETDATE(), WinlostDate = @WinlostDate, LogDesc = 'Successfully'
			WHERE QueueId = @QueueId

			SELECT @QueueId = NULL, @XmlData = NULL

			SELECT TOP 1 @QueueId = QueueId, @XmlData = XmlData
			FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
			WHERE ProductId = @ProductId AND JobType = 1 AND FinishedTime IS NULL
			ORDER BY QueueId
		END
	END

	IF ISNULL(@ListQueueId, '') <> ''
	BEGIN
		SELECT @ErrCode = 500, @ErrMsg = @ListQueueId
	END

	DROP TABLE #Ebet
	DROP TABLE #Betsoft
END
GO