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
		- 20190716@Percy: Do not run if MB does not run [RedmineID: #116964]
*/

BEGIN 
	SET NOCOUNT ON

	-- Check today MB run or not
	DECLARE @MoveBetSchedule TABLE(ScheduleId TINYINT, MoveBetDay DATE)
	
	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF NOT EXISTS (SELECT TOP 1 1 FROM @MoveBetSchedule)
	BEGIN
		RETURN
	END

	DECLARE @IsMatched BIT = 0, @ProductList VARCHAR(50) = ''
	DECLARE @ErrTable TABLE (WinlostDate SMALLDATETIME, ProductId INT)
	
	DECLARE @winlostdate SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
	DECLARE @MBBUDate TABLE (MoveBetsDay SMALLDATETIME, BalanceUpDay SMALLDATETIME)
	
	INSERT INTO @MBBUDate (MoveBetsDay, BalanceUpDay)
	EXEC DBEXT.bodb02.dbo.Lrf_SelBalanceUpDay
		
	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay
	FROM @MBBUDate
		
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