USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_ImportData_API_Job]    Script Date: 11/30/2018 7:38:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

	DECLARE @tblWinlostDate TABLE (WinlostDate SMALLDATETIME, MaxQueueId BIGINT)

	DECLARE @OldLastQueueId BIGINT, @NewLastQueueId BIGINT, @WinlostDate SMALLDATETIME,
			@LaunchDate SMALLDATETIME, @FromImportDate SMALLDATETIME

	DECLARE @ErrTable TABLE (ProductId INT, WinlostDate SMALLDATETIME)

	-- AG Casino
	BEGIN
		-- Reset data
		SELECT @OldLastQueueId = NULL, @NewLastQueueId = NULL, @WinlostDate = NULL, @LaunchDate = NULL, @FromImportDate = NULL
		
		DELETE @tblWinlostDate
		
		SELECT @OldLastQueueId = CONVERT(BIGINT, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId = 9 AND SettingName = 'LastQueueId'

		SELECT @LaunchDate = CONVERT(SMALLDATETIME, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId = 9 AND SettingName = 'LaunchDate'

		SELECT @FromImportDate = CASE WHEN @LaunchDate > @MaxCommDate THEN @LaunchDate ELSE DATEADD(DAY, 1, @MaxCommDate) END
	
		INSERT INTO @tblWinlostDate (WinlostDate, MaxQueueId)
		SELECT WinlostDate, MAX(QueueId) FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
		WHERE ProductId = 10 AND QueueId > @OldLastQueueId AND WinlostDate >= @FromImportDate
		GROUP BY WinlostDate

		SELECT @NewLastQueueId = MAX(MaxQueueId) FROM @tblWinlostDate
		SELECT @NewLastQueueId = ISNULL(@NewLastQueueId, @OldLastQueueId)

		SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate

		WHILE @WinlostDate IS NOT NULL
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_Aff_ImportData_AGCasino @WinlostDate = @WinlostDate
			END TRY
			BEGIN CATCH
				INSERT INTO @ErrTable (ProductId, WinlostDate)
				VALUES (10, @WinlostDate)
			END CATCH
			
			DELETE @tblWinlostDate WHERE WinlostDate = @WinlostDate
			
			SELECT @WinlostDate = NULL
			SELECT TOP 1 @WinlostDate = WinlostDate FROM @tblWinlostDate ORDER BY WinlostDate
		END

		UPDATE dbo.APIProductSettings WITH (ROWLOCK, UPDLOCK)
		SET SettingValue = CONVERT(VARCHAR(200), @NewLastQueueId)
		WHERE ProductId = 9 AND SettingName = 'LastQueueId'
	END

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