/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_Process_Job]
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse xml data from Queue

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20191010@Percy: Clean old data (keep 3 months) [RedmineID: #121795]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Products TABLE (Id INT IDENTITY(1,1), ProductId INT)
	
	INSERT INTO @Products (ProductId)
	SELECT ProductId FROM dbo.APIProductSettings WITH (NOLOCK)
	WHERE SettingName = 'SourceTable' AND SettingValue = 'APIProduct_ImportQueue'

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(4000)
	DECLARE @ErrTable TABLE (ProductId INT, ErrMsg NVARCHAR(4000))

	DECLARE @Id INT = 1, @ProductId INT = NULL
	SELECT  @ProductId = ProductId FROM @Products WHERE Id = @Id

	WHILE @ProductId IS NOT NULL
	BEGIN
		-- Clean old data (keep 3 months)
		IF EXISTS (
			SELECT 1 FROM dbo.APIProduct_ImportQueue WITH (NOLOCK)
			WHERE ProductId = @ProductId AND WinlostDate < DATEADD(MONTH, -3, GETDATE())
				AND FinishedTime IS NOT NULL
		)
		BEGIN
			WHILE 1 = 1
			BEGIN
				DELETE TOP (2000) FROM dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK)
				WHERE ProductId = @ProductId AND WinlostDate < DATEADD(MONTH, -3, GETDATE())
					AND FinishedTime IS NOT NULL

				IF @@ROWCOUNT < 2000
					BREAK

				WAITFOR DELAY '00:00:00.280'
			END
		END

		-- Parse data
		SELECT @ErrCode = 0, @ErrMsg = ''
		
		BEGIN TRY
			EXEC dbo.Task_APIProduct_ImportQueue_Process @ProductId = @ProductId, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode <> 0
				INSERT INTO @ErrTable (ProductId, ErrMsg)
				VALUES (@ProductId, @ErrMsg)
		END TRY
		BEGIN CATCH
			INSERT INTO @ErrTable (ProductId, ErrMsg)
			VALUES (@ProductId, ERROR_MESSAGE())
		END CATCH

		SELECT @Id = @Id + 1
		SELECT @ProductId = NULL
		SELECT @ProductId = ProductId FROM @Products WHERE Id = @Id
	END

	-- Send mail if have error
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) = ''

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Import raw data from queue table (API)'' failed on ' + @@SERVERNAME

		SELECT @Msg = '<H3>List of products have wrong data</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>Product</th><th>WinlostDate</th></tr>'
						+ CAST((SELECT	td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
										td = p.ProductName, '',
										td = e.ErrMsg, ''
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