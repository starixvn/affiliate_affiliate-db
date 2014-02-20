ALTER PROCEDURE [dbo].[Task_Aff_DailyImportExchange]
	@Date	SMALLDATETIME=NULL,
	@Xml	XML = NULL
AS
/*
	Created: 20110223@Peter
	Task : Import s FROM IBC
	DB: DB052.Affiliate_ZZun
	Revisions:
		- 20110223@Peter: initialize SP
		- 20140110@Bobby.Nguyen: Add KRW & JPY currency
		- 20140219@Dan.Nguyen: Update for supporting duplicate currency from XML
		
*/
BEGIN

	SET NOCOUNT ON;

	SELECT @Date = COALESCE(CONVERT(VARCHAR(10)	, @Date, 120), CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120));

	DECLARE @count INT;

	DECLARE @TempTrans TABLE(
		ExchangeDate DATETIME
		, ExchangeID SMALLINT
		, Code VARCHAR(5)
		, MYR FLOAT
		, USD FLOAT
		, EUR FLOAT
		, CNY FLOAT
		, SGD FLOAT
		, IDR FLOAT
		, AUD FLOAT
		, CHF FLOAT
		, GBP FLOAT
		, THB FLOAT
		, VND FLOAT
		, KRW FLOAT
		, JPY FLOAT
		)

	INSERT INTO @TempTrans --Convert xml to table
	SELECT	
			[Table].[Column].value('./@exchangedate', 'DATETIME') AS ExchangeDate
			, [Table].[Column].value('./@exchangeid', 'SMALLINT') AS ExchangeID
			, [Table].[Column].value('./@code', 'VARCHAR(5)') AS Code
			, [Table].[Column].value('./@myr', 'FLOAT') AS MYR
			, [Table].[Column].value('./@usd', 'FLOAT') AS USD				
			, [Table].[Column].value('./@eur', 'FLOAT') AS EUR
			, [Table].[Column].value('./@cny', 'FLOAT') AS CNY		
			, [Table].[Column].value('./@sgd', 'FLOAT') AS SGD
			, [Table].[Column].value('./@idr', 'FLOAT') AS IDR
			, [Table].[Column].value('./@aud', 'FLOAT') AS AUD
			, [Table].[Column].value('./@chf', 'FLOAT') AS CHF
			, [Table].[Column].value('./@gbp', 'FLOAT') AS GBP
			, [Table].[Column].value('./@thb', 'FLOAT') AS THB
			, [Table].[Column].value('./@vnd', 'FLOAT') AS VND
			, [Table].[Column].value('./@krw', 'FLOAT') AS KRW
			, [Table].[Column].value('./@jpy', 'FLOAT') AS JPY
	FROM @Xml.nodes('/root/trans') AS [Table]([Column])
	
	DELETE @TempTrans
	WHERE ExchangeID NOT IN (SELECT PartnerExchangeID from CurrencyConverter WITH (NOLOCK))

	UPDATE  @TempTrans
	SET  MYR=(CASE WHEN code<>'MYR' THEN MYR/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='MYR') ELSE MYR END)
		,USD=(CASE WHEN code<>'USD' THEN USD/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='USD') ELSE USD END)
		,EUR=(CASE WHEN code<>'EUR' THEN EUR/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='EUR') ELSE EUR END)
		,CNY=(CASE WHEN code<>'CNY' THEN CNY/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='CNY') ELSE CNY END)
		,IDR=(CASE WHEN code<>'IDR' THEN IDR/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='IDR') ELSE IDR END)
		,AUD=(CASE WHEN code<>'AUD' THEN AUD/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='AUD') ELSE AUD END)
		,CHF=(CASE WHEN code<>'CHF' THEN CHF/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='CHF') ELSE CHF END)
		,GBP=(CASE WHEN code<>'GBP' THEN GBP/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='GBP') ELSE GBP END)
		,SGD=(CASE WHEN code<>'SGD' THEN SGD/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='SGD') ELSE SGD END)
		,THB=(CASE WHEN code<>'THB' THEN THB/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='THB') ELSE THB END)
		,VND=(CASE WHEN code<>'VND' THEN VND/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='VND') ELSE VND END)
		,KRW=(CASE WHEN code<>'KRW' THEN KRW/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='KRW') ELSE KRW END)
		,JPY=(CASE WHEN code<>'JPY' THEN JPY/(SELECT ISNULL(MultipliedBy,1) FROM Currency WHERE currencycode='JPY') ELSE JPY END)


	UPDATE ec
	SET  USD = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.USD,ec.USD,0) ELSE ec.USD END)
		,USD_Market = COALESCE(ed.usd,ec.USD_Market,0)
		,EUR = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.EUR,ec.EUR,0) ELSE ec.EUR END)
		,EUR_Market = COALESCE(ed.EUR,ec.EUR_Market,0)
		,CNY = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.CNY,ec.CNY,0) ELSE ec.CNY END)
		,CNY_Market = COALESCE(ed.CNY,ec.CNY_Market,0)
		,UUS = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.UUS END)
		,UUS_Market = 2E-102
		,MYR = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.MYR,ec.MYR,0) ELSE ec.MYR END)
		,MYR_Market = COALESCE(ed.MYR,ec.MYR_Market,0)
		,SGD = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.SGD,ec.SGD,0) ELSE ec.SGD END)
		,SGD_Market = COALESCE(ed.SGD,ec.SGD_Market,0)
		,IDR = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.IDR,ec.IDR,0) ELSE ec.IDR END)
		,IDR_Market = COALESCE(ed.IDR,ec.IDR_Market,0)
		,AUD = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.AUD,ec.AUD,0) ELSE ec.AUD END)
		,AUD_Market = COALESCE(ed.AUD,ec.AUD_Market,0)
		,CHF = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.CHF,ec.CHF,0) ELSE ec.CHF END)
		,CHF_Market = COALESCE(ed.CHF,ec.CHF_Market,0)
		,GBP = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.GBP,ec.GBP,0) ELSE ec.GBP END)
		,GBP_Market = COALESCE(ed.GBP,ec.GBP_Market,0)
		,THB = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.THB,ec.THB,0) ELSE ec.THB END)
		,THB_Market = COALESCE(ed.THB,ec.THB_Market,0)
		,VND = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.VND,ec.VND,0) ELSE ec.VND END)
		,VND_Market = COALESCE(ed.VND,ec.VND_Market,0)
		,KRW = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.KRW,ec.KRW,0) ELSE ec.KRW END)
		,KRW_Market = COALESCE(ed.KRW,ec.KRW_Market,0)
		,JPY = (CASE WHEN IsAutoRefresh = 1 THEN COALESCE(ed.JPY,ec.JPY,0) ELSE ec.JPY END)
		,JPY_Market = COALESCE(ed.JPY,ec.JPY_Market,0)
	FROM dbo.Exchange ec WITH(ROWLOCK, UPDLOCK)	
		INNER JOIN dbo.CurrencyConverter cc WITH(NOLOCK) ON ec.ExchangeID = cc.ExchangeID
		INNER JOIN @TempTrans AS ed ON ed.ExchangeID = cc.PartnerExchangeID
	WHERE exchangedate = @date

	-- update for UUS currency

	UPDATE ec
	SET  UUS=1
		 ,UUS_Market=1	
		,USD_Market = 2E-102
		,USD = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.USD END)
		,EUR = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.EUR END)
		,EUR_Market =  2E-102
		,CNY = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.CNY END)
		,CNY_Market =  2E-102
		,MYR = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.MYR END)
		,MYR_Market =  2E-102
		,SGD = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.SGD END)
		,SGD_Market =  2E-102
		,IDR = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.IDR END)
		,IDR_Market =  2E-102
		,AUD = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.AUD END)
		,AUD_Market =  2E-102
		,CHF = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.CHF END)
		,CHF_Market = 2E-102
		,GBP = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.GBP END)
		,GBP_Market =  2E-102
		,THB = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.THB END)
		,THB_Market =  2E-102
		,VND = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.VND END)
		,VND_Market =  2E-102
		,KRW = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.KRW END)
		,KRW_Market =  2E-102
		,JPY = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.JPY END)
		,JPY_Market =  2E-102
	FROM dbo.Exchange ec WITH(ROWLOCK, UPDLOCK)		
	WHERE ExchangeID = 9999


	IF (@@ROWCOUNT = 0)
	BEGIN
		PRINT 'No data available for this day!';
		RETURN;
	END

	--megre to ExchangeDaily
	;WITH tmpExchange AS
	(
		SELECT @Date AS [Date]
			, ex.* 
		FROM dbo.Exchange ex WITH(NOLOCK)

	) MERGE INTO dbo.ExchangeDaily AS exd
	USING tmpExchange AS ex 
	ON exd.ExchangeID = ex.ExchangeID AND exd.[Date] = ex.[Date]
	WHEN MATCHED THEN
		UPDATE 
		SET [USD]			= ex.USD
			,[USD_Market]	= ex.USD_Market
			,[EUR]			= ex.EUR
			,[EUR_Market]	= ex.EUR_Market
			,[CNY]			= ex.CNY
			,[CNY_Market]	= ex.CNY_Market
			,[UUS]			= ex.UUS
			,[UUS_Market]	= ex.UUS_Market
			,[MYR]			= ex.MYR
			,[MYR_Market]	= ex.MYR_Market
			,[Code]			= ex.Code
			,[SGD]			= ex.SGD
			,[SGD_Market]	= ex.SGD_Market
			,[IDR]			= ex.IDR
			,[IDR_Market]	= ex.IDR_Market
			,[AUD]			= ex.AUD
			,[AUD_Market]	= ex.AUD_Market
			,[CHF]			= ex.CHF
			,[CHF_Market]	= ex.CHF_Market
			,[GBP]			= ex.GBP
			,[GBP_Market]	= ex.GBP_Market
			,[THB]			= ex.THB
			,[THB_Market]	= ex.THB_Market
			,[VND]			= ex.VND
			,[VND_Market]	= ex.VND_Market
			,[KRW]			= ex.KRW
			,[KRW_Market]	= ex.KRW_Market
			,[JPY]			= ex.JPY
			,[JPY_Market]	= ex.JPY_Market
			,[DepositPercent]		= ex.DepositPercent
			,[WithdrawalPercent]	= ex.WithdrawalPercent
			,[IsAutoRefresh]		= ex.IsAutoRefresh

	WHEN NOT MATCHED BY TARGET THEN
		INSERT([Date],ExchangeID
			,USD,USD_Market
			,EUR,EUR_Market
			,CNY,CNY_Market
			,UUS,UUS_Market
			,MYR,MYR_Market
			,SGD,SGD_Market
			,IDR,IDR_Market
			,AUD,AUD_Market
			,CHF,CHF_Market
			,GBP,GBP_Market
			,THB,THB_Market
			,VND,VND_Market
			,KRW,KRW_Market
			,JPY,JPY_Market
			,Code,DepositPercent
			,WithdrawalPercent,IsAutoRefresh)
		VALUES (@Date,ex.ExchangeID
			,ex.USD,ex.USD_Market
			,ex.EUR,ex.EUR_Market
			,ex.CNY,ex.CNY_Market
			,ex.UUS,ex.UUS_Market
			,ex.MYR,ex.MYR_Market
			,ex.SGD,ex.SGD_Market
			,ex.IDR,ex.IDR_Market
			,ex.AUD,ex.AUD_Market
			,ex.CHF,ex.CHF_Market
			,ex.GBP,ex.GBP_Market
			,ex.THB,ex.THB_Market
			,ex.VND,ex.VND_Market
			,ex.KRW,ex.KRW_Market
			,ex.JPY,ex.JPY_Market
			,ex.Code,ex.DepositPercent
			,ex.WithdrawalPercent,ex.IsAutoRefresh);

	-- if the date < current_date and date > max(winlostdate FROM commission)
	-- update all data for MemberDaily,MemberDailyRemoved, AffDaily,AffDailySummary

	DECLARE @TaskID INT
		, @LogID	INT
		, @RunDate	DATETIME
		, @Status	VARCHAR(50)

	SELECT @RunDate=GETDATE()
		, @Status='completed'

	SELECT @TaskID= TaskID 
	FROM dbo.TaskManager WITH(NOLOCK) 
	WHERE TaskName='Import Exchange Daily';

	EXEC [dbo].[Aff_TaskLogIns]
		@TaskID		= @TaskID,
		@RunDate	= @RunDate,
		@Status		= @Status,
		@LogID		= @LogID OUTPUT;
END

GO


