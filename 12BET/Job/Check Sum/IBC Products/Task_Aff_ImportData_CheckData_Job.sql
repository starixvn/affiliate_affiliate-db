/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_CheckData_Job]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Import data of IBC's Products from bettrans (MoveBetsDays)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190116@Percy: Send mail if data has mismatch [RedmineID: #107623]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @IsMatched BIT = 0, @ProductList VARCHAR(50) = ''
	DECLARE @ErrTable TABLE (WinlostDate SMALLDATETIME, ProductId INT)
	
	DECLARE @winlostdate SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
		
	SELECT @MoveBetsDay = MAX(eventdate)
	FROM bodb02.dbo.match14 WITH(NOLOCK)
		
	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE matchid = 0 AND bettype = 20000
		
	SELECT @winlostdate = @BalanceUpDay
		
	WHILE(@winlostdate <= @MoveBetsDay)
	BEGIN
		SELECT @IsMatched = 0, @ProductList = NULL
		
		EXEC dbo.Task_Aff_ImportData_CheckData @winlostdate = @winlostdate, @isCheckOnly = 0, @IsMatched = @IsMatched OUTPUT, @ProductList = @ProductList OUTPUT

		IF @IsMatched = 0
		BEGIN
			INSERT INTO @ErrTable (WinlostDate, ProductId)
			SELECT @winlostdate, CONVERT(INT, val)
			FROM dbo.Aff_f_StringSplit(@ProductList, ',')
		END
			
		SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
	END

	-- Send mail if has mismatch data
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX) = ''

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Affiliate_12BET: Check and Correct Member Data Daily'' on ' + @@SERVERNAME

		SELECT @Msg = '<H3>Data on rptMemberDaily is not matched with source.</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>WinlostDate</th><th>Product</th></tr>'
						+ CAST((SELECT	td = ROW_NUMBER() OVER(ORDER BY e.WinlostDate, e.ProductId), '',
									td = CONVERT(VARCHAR(10), e.WinlostDate, 120), '',
									td = ISNULL(p.ProductName, CONVERT(VARCHAR(5), e.ProductId)), ''
								FROM @ErrTable e
									LEFT JOIN dbo.Products p WITH (NOLOCK) ON e.ProductId = p.ProductID
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