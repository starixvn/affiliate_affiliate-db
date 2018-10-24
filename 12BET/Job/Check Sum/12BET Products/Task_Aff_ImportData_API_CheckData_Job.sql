/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_API_CheckData_Job]
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

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME, @WinlostDate SMALLDATETIME,
			@LaunchDate SMALLDATETIME, @FromImportDate SMALLDATETIME

	DECLARE @ErrTable TABLE (ProductId INT, WinlostDate SMALLDATETIME)

	DECLARE @LastQueueId BIGINT

	-- AG Casino
	BEGIN
		-- Reset data
		SELECT @LastQueueId = NULL, @WinlostDate = NULL, @LaunchDate = NULL, @FromImportDate = NULL
		
		SELECT @LastQueueId = CONVERT(BIGINT, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId = 9 AND SettingName = 'LastQueueId'

		SELECT @LaunchDate = CONVERT(SMALLDATETIME, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE ProductId = 9 AND SettingName = 'LaunchDate'

		SELECT @FromImportDate = CASE WHEN @LaunchDate > @MaxCommDate THEN @LaunchDate ELSE DATEADD(DAY, 1, @MaxCommDate) END

		SELECT @FromDate = MIN(WinlostDate), @ToDate = MAX(WinlostDate)
		FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
		WHERE ProductId = 10 AND QueueId <= @LastQueueId AND WinlostDate >= @FromImportDate

		SELECT @WinlostDate = @FromDate

		WHILE @WinlostDate <= @ToDate
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_Aff_ImportData_AGCasino_CheckData @WinlostDate = @WinlostDate, @IsCheckDataOnly = 0
			END TRY
			BEGIN CATCH
				INSERT INTO @ErrTable (ProductId, WinlostDate)
				VALUES (10, @WinlostDate)
			END CATCH
			
			SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
		END
	END

	-- Send mail if have error
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) = ''

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Check data from raw table (API)'' failed on ' + @@SERVERNAME

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