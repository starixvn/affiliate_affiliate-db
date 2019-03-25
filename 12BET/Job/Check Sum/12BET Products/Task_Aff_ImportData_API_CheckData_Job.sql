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
		- 20190117@Percy: Using core table for 3rd Products [RedmineID: #106503]
		- 20190322@Percy: Missing break loop [RedmineID: #110638]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_CommissionDate'

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME, @WinlostDate SMALLDATETIME,
			@LaunchDate SMALLDATETIME, @FromImportDate SMALLDATETIME

	DECLARE @ErrTable TABLE (ProductId INT, WinlostDate SMALLDATETIME, ErrMsg NVARCHAR(4000))

	DECLARE @Products TABLE (Id INT IDENTITY(1,1), ProductId INT, LaunchDate SMALLDATETIME)
	DECLARE @Id INT = 1, @ProductId INT = NULL

	DECLARE @LastQueueId BIGINT

	-- 3rd Products: Product3rd_ImportQueue
	BEGIN
		DECLARE @3rdProductId INT
		
		SELECT @Id = 1, @ProductId = NULL
		
		DELETE @Products

		INSERT INTO @Products (ProductId)
		SELECT ProductId FROM dbo.APIProductSettings WITH (NOLOCK)
		WHERE SettingName = 'SourceTable' AND SettingValue = '3rdProducts'

		UPDATE p
		SET p.LaunchDate = CONVERT(SMALLDATETIME, aps.SettingValue)
		FROM @Products p
			INNER JOIN dbo.APIProductSettings aps WITH (NOLOCK) ON p.ProductId = aps.ProductId AND aps.SettingName = 'LaunchDate'

		SELECT @ProductId = ProductId, @LaunchDate = LaunchDate FROM @Products WHERE Id = @Id

		WHILE @ProductId IS NOT NULL
		BEGIN
			-- Reset data
			SELECT @LastQueueId = NULL, @WinlostDate = NULL, @LaunchDate = NULL, @FromImportDate = NULL, @3rdProductId = NULL

			SELECT @3rdProductId = CONVERT(INT, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
			WHERE ProductId = @ProductId AND SettingName = '3rdProductId'
		
			SELECT @LastQueueId = CONVERT(BIGINT, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
			WHERE ProductId = @ProductId AND SettingName = 'LastQueueId'

			SELECT @LaunchDate = CONVERT(SMALLDATETIME, SettingValue) FROM dbo.APIProductSettings WITH (NOLOCK)
			WHERE ProductId = @ProductId AND SettingName = 'LaunchDate'

			SELECT @FromImportDate = CASE WHEN @LaunchDate > @MaxCommDate THEN @LaunchDate ELSE DATEADD(DAY, 1, @MaxCommDate) END

			SELECT @FromDate = MIN(WinlostDate), @ToDate = MAX(WinlostDate)
			FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
			WHERE ProductId = @3rdProductId AND QueueId <= @LastQueueId AND WinlostDate >= @FromImportDate

			SELECT @WinlostDate = @FromDate

			WHILE @WinlostDate <= @ToDate
			BEGIN
				BEGIN TRY
					EXEC dbo.Task_Aff_ImportData_3rdProduct_CheckData @ProductId = @ProductId, @WinlostDate = @WinlostDate, @IsCheckDataOnly = 0
				END TRY
				BEGIN CATCH
					INSERT INTO @ErrTable (ProductId, WinlostDate, ErrMsg)
					VALUES (@ProductId, @WinlostDate, ERROR_MESSAGE())
				END CATCH
			
				SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
			END

			SELECT @Id = @Id + 1
			SELECT @ProductId = NULL, @LaunchDate = NULL
			SELECT @ProductId = ProductId, @LaunchDate = LaunchDate FROM @Products WHERE Id = @Id
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