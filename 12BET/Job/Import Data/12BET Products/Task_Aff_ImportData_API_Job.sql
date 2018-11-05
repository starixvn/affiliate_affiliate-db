/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_API_Job]
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - API Products

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_CommissionDate'

	-- List of import products
	DECLARE @ImportProducts TABLE (Id INT IDENTITY(1,1), ProductId INT, OldLastQueueId BIGINT, NewLastQueueId BIGINT, FromImportDate SMALLDATETIME)

	INSERT INTO @ImportProducts (ProductId, OldLastQueueId)
	SELECT ProductId, CONVERT(BIGINT, SettingValue)
	FROM dbo.APIProductSettings WITH (NOLOCK)
	WHERE SettingName = 'LastQueueId'

	UPDATE p
	SET p.FromImportDate = CASE WHEN CONVERT(SMALLDATETIME, SettingValue) > @MaxCommDate THEN CONVERT(SMALLDATETIME, SettingValue) ELSE DATEADD(DAY, 1, @MaxCommDate) END
	FROM @ImportProducts p
		INNER JOIN dbo.APIProductSettings s WITH (NOLOCK) ON p.ProductId = s.ProductId
	WHERE s.SettingName = 'LaunchDate'

	DELETE @ImportProducts WHERE FromImportDate IS NULL OR FromImportDate > CONVERT(DATE, GETDATE())

	DECLARE @tblWinlostDate TABLE (WinlostDate SMALLDATETIME, MaxQueueId BIGINT)

	DECLARE @Id INT, @ProductId INT, @OldLastQueueId BIGINT, @NewLastQueueId BIGINT, @WinlostDate SMALLDATETIME, @FromImportDate SMALLDATETIME

	DECLARE @ErrTable TABLE (ProductId INT, WinlostDate SMALLDATETIME)

	SELECT  @Id = 1

	SELECT  @ProductId = ProductId, @OldLastQueueId = OldLastQueueId, @FromImportDate = FromImportDate
	FROM @ImportProducts WHERE Id = @Id

	WHILE @ProductId IS NOT NULL
	BEGIN
		DELETE @tblWinlostDate
		
		-- AG Casino
		IF @ProductId = 9
		BEGIN
			INSERT INTO @tblWinlostDate (WinlostDate, MaxQueueId)
			SELECT WinlostDate, MAX(QueueId) FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE ProductId = 10 AND QueueId > @OldLastQueueId AND WinlostDate >= @FromImportDate
			GROUP BY WinlostDate

			SELECT @NewLastQueueId = MAX(MaxQueueId) FROM @tblWinlostDate
			SELECT @NewLastQueueId = ISNULL(@NewLastQueueId, @OldLastQueueId)

			UPDATE @ImportProducts
			SET NewLastQueueId = @NewLastQueueId
			WHERE ProductId = @ProductId

			SELECT @WinlostDate = NULL
			SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate

			WHILE @WinlostDate IS NOT NULL
			BEGIN
				BEGIN TRY
					EXEC dbo.Task_Aff_ImportData_AGCasino @WinlostDate = @WinlostDate
				END TRY
				BEGIN CATCH
					INSERT INTO @ErrTable (ProductId, WinlostDate)
					VALUES (@ProductId, @WinlostDate)
				END CATCH
			
				DELETE @tblWinlostDate WHERE WinlostDate = @WinlostDate
			
				SELECT @WinlostDate = NULL
				SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate
			END
		END
		-- Products in APIProduct_ImportQueue table
		ELSE IF EXISTS (
			SELECT 1 FROM dbo.APIProductSettings WITH (NOLOCK)
			WHERE ProductId = @ProductId AND SettingName = 'SourceTable' AND SettingValue = 'APIProduct_ImportQueue'
		)
		BEGIN
			INSERT INTO @tblWinlostDate (WinlostDate, MaxQueueId)
			SELECT WinlostDate, MAX(QueueId) FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
			WHERE ProductId = @ProductId AND QueueId > @OldLastQueueId AND WinlostDate >= @FromImportDate
			GROUP BY WinlostDate

			SELECT @NewLastQueueId = MAX(MaxQueueId) FROM @tblWinlostDate
			SELECT @NewLastQueueId = ISNULL(@NewLastQueueId, @OldLastQueueId)

			UPDATE @ImportProducts
			SET NewLastQueueId = @NewLastQueueId
			WHERE ProductId = @ProductId

			SELECT @WinlostDate = NULL
			SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate

			WHILE @WinlostDate IS NOT NULL
			BEGIN
				BEGIN TRY
					EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate
				END TRY
				BEGIN CATCH
					INSERT INTO @ErrTable (ProductId, WinlostDate)
					VALUES (@ProductId, @WinlostDate)
				END CATCH
			
				DELETE @tblWinlostDate WHERE WinlostDate = @WinlostDate
			
				SELECT @WinlostDate = NULL
				SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate
			END
		END

		SELECT @ProductId = NULL, @OldLastQueueId = NULL, @NewLastQueueId = NULL, @FromImportDate = NULL
		
		SELECT @Id = @Id + 1

		SELECT @ProductId = ProductId, @OldLastQueueId = OldLastQueueId, @FromImportDate = FromImportDate
		FROM @ImportProducts WHERE Id = @Id
	END

	UPDATE s WITH (ROWLOCK, UPDLOCK)
	SET s.SettingValue = CONVERT(VARCHAR(200), @NewLastQueueId)
	FROM dbo.APIProductSettings s
		INNER JOIN @ImportProducts p ON s.ProductId = p.ProductId
	WHERE s.SettingName = 'LastQueueId'

	-- Send mail if have error
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) = ''

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Import data from raw table (API)'' failed on ' + @@SERVERNAME

		SELECT @Msg = '<H3>List of products have wrong data</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>Product</th><th>WinlostDate</th></tr>'
						+ CAST((SELECT	td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
										td = p.ProductName, '',
										td = e.WinlostDate, ''
								FROM @ErrTable e
									INNER JOIN dbo.Products p WITH (NOLOCK) ON e.ProductId = p.ProductID
								FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX)) + N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= 'percy.nguyen@starixsoft.com;pontus@starixsoft.com',
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML'
	END
END
GO