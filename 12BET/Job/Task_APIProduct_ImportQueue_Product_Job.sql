/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_Product_Job]
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

	DECLARE @today SMALLDATETIME, @WinlostDate SMALLDATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())

	DECLARE @Products TABLE (Id INT IDENTITY(1,1), ProductId INT)
	
	INSERT INTO @Products (ProductId)
	SELECT ProductId FROM dbo.APIProductSettings WITH (NOLOCK)
	WHERE SettingName = 'SourceTable' AND SettingValue = 'APIProduct_ImportQueue'

	DECLARE @ErrTable TABLE (ProductId INT, winlostdate SMALLDATETIME, ErrMsg NVARCHAR(4000))

	DECLARE @Id INT = 1, @ProductId INT = NULL
	SELECT  @ProductId = ProductId FROM @Products WHERE Id = @Id

	WHILE @ProductId IS NOT NULL
	BEGIN
		SELECT @WinlostDate = DATEADD(DAY, -2, @today)

		WHILE @WinlostDate <= @today
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_APIProduct_ImportQueue_Product @ProductId = @ProductId, @WinlostDate = @WinlostDate
			END TRY
			BEGIN CATCH
				INSERT INTO @ErrTable (ProductId, ErrMsg)
				VALUES (@ProductId, ERROR_MESSAGE())
			END CATCH

			SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
		END
		SELECT @Id = @Id + 1
		SELECT @ProductId = NULL
		SELECT @ProductId = ProductId FROM @Products WHERE Id = @Id
	END

	-- Send mail if have error
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) = ''

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Import data from raw table'' failed on ' + @@SERVERNAME

		SELECT @Msg = '<H3>List of products have wrong data</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>Product</th><th>WinlostDate</th></tr>'
						+ CAST((SELECT	td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
										td = p.ProductName, '',
										td = CONVERT(VARCHAR(20), e.WinlostDate, 120), '',
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