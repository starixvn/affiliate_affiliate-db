ALTER PROCEDURE [dbo].[Task_Aff_MemberDailyImportData] 
	@AdminID INT
	,@XmlData XML
	,@WinlostDate SMALLDATETIME
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(500) = '' OUTPUT
AS
/*3
	Task : Import member daily transaction from xml into table MemberDaily
	Author : 20130114@Joseph
	DB: DBAFF/Affiliate_Athena000
	Original: [Aff_MemberDailyImportData]
	Revisions: 		
		- 20140509@Dan: support Playtech casino
		- 20140610@Bobby: Add PShare & PWin columns
		- 20150102@Bobby.Nguyen: Add more product list - change API_ProductId to bodb02.dbo.Products.ProductID
*/
BEGIN
	SET NOCOUNT ON

	-- check data is calculated for this month?
	IF EXISTS (
			SELECT TOP (1) 1
			FROM AffCommission(NOLOCK)
			WHERE DATEDIFF(m, @WinlostDate, Winlostdate) = 0
			) RETURN

	DECLARE @SystemCurrency SMALLINT

	EXEC Aff_GetSystemCurrency @SystemCurrency = @SystemCurrency OUTPUT

	DECLARE @TmpTable TABLE (
		UserName VARCHAR(30)
		,WinlostDate SMALLDATETIME
		,ProductID TINYINT
		)
	--Import new Data here
	DECLARE @TempTrans TABLE (
		UserName VARCHAR(30)
		,WinlostDate SMALLDATETIME
		,ProductID TINYINT
		,Turnover MONEY
		,Outstanding MONEY
		,Winlost MONEY
		,DrawGame MONEY
		,BetCount INT
		,PlayerComm MONEY
		,TurnoverNoDraw MONEY
		,BetCountNoDraw INT
		,PShare MONEY
		,PWin MONEY
	);

	INSERT INTO @TempTrans (
		UserName
		,WinlostDate
		,ProductID
		,Turnover
		,Outstanding
		,Winlost
		,DrawGame
		,BetCount
		,PlayerComm
		,TurnoverNoDraw
		,BetCountNoDraw
		,PShare
		,PWin
	)
	SELECT [Table].[Column].value('./@username', 'varchar(30)') AS [UserName]
		,[Table].[Column].value('./@winlostdate', 'smalldatetime') AS [WinlostDate]
		,[Table].[Column].value('./@productid', 'tinyint') AS [ProductID]
		,[Table].[Column].value('./@turnover', 'money') AS [Turnover]
		,[Table].[Column].value('./@outstanding', 'money') AS [Outstanding]
		,[Table].[Column].value('./@winloss', 'money') AS [Winlost]
		,[Table].[Column].value('./@drawgame', 'money') AS [DrawGame]
		,[Table].[Column].value('./@betcount', 'int') AS [betcount]
		,[Table].[Column].value('./@playercomm', 'money') AS [PlayerComm]
		,[Table].[Column].value('./@turnovernodraw', 'money') AS [TurnoverNoDraw]
		,[Table].[Column].value('./@betcountnodraw', 'int') AS [BetCountNoDraw]
		,[Table].[Column].value('./@progressiveshare', 'money') AS [PShare]
		,[Table].[Column].value('./@progressivewin', 'money') AS [PWin]
	FROM @XmlData.nodes('/root/trans') AS [Table]([Column]);

	DELETE MemberDaily WITH(ROWLOCK)
	WHERE WinlostDate = @WinlostDate

	INSERT INTO MemberDaily (
		[UserName]
		,[WinlostDate]
		,[ProductID]
		,[Turnover]
		,[Outstanding]
		,[Winlost]
		,[DrawGame]
		,[AffId]
		,[IBCCustId]
		,[Currency]
		,[AffCurrency]
		,[AffExRate]
		,[SysCurrency]
		,[SysExRate]
		,[Deposit]
		,[Withdrawal]
		,[Bonus]
		,[Adjustment]
		,[BetCount]
		,[PlayerComm]
		,[BetCountNoDraw]
		,[TurnoverDraw]
		,[TurnoverNoDraw]
		,[PShare]
		,[PWin]
		)
	SELECT t1.UserName
		,t1.WinlostDate
		,p.ProductID
		,t1.Turnover
		,t1.Outstanding
		,t1.Winlost
		,t1.DrawGame
		,mi.AffId
		,mi.IBCCustId
		,mi.Currency
		,ai.Currency
		,dbo.Aff_GetExchangeRate(mi.Currency, ai.Currency, @WinlostDate) AS AffExRate
		,@SystemCurrency
		,dbo.Aff_GetExchangeRate(mi.Currency, @SystemCurrency, @WinlostDate) AS SystemExRate
		,0 AS Deposit
		,0 AS Withdrawal
		,0 AS Bonus
		,0 AS Adjustment
		,t1.BetCount
		,t1.PlayerComm
		,t1.BetCountNoDraw
		,t1.DrawGame
		,t1.TurnoverNoDraw
		,t1.PShare
		,t1.PWin
	FROM @TempTrans AS t1
		INNER JOIN dbo.MemberInfo AS mi ON t1.UserName = mi.UserName
		INNER JOIN dbo.AffInfo AS ai WITH (NOLOCK) ON mi.AffId = ai.AffId
	-- inner join Exchange as ex with (nolock) on ai.Currency = ex.ExchangeId
		INNER JOIN dbo.Product AS p WITH (NOLOCK) ON t1.ProductID = p.API_ProductId
		AND p.IsEnabled = 1
		AND p.EffectiveDate <= @WinlostDate
	WHERE t1.WinlostDate = @WinlostDate
		AND mi.IsRemoved = 0
END
GO

GRANT EXECUTE ON [dbo].[Task_Aff_MemberDailyImportData] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailyImportData] TO [vnteam] AS [dbo]