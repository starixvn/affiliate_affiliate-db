ALTER PROCEDURE [dbo].[Task_Aff_MemberDailyImportData]	
	@AdminID int,	
	@XmlData XML,
	@WinlostDate smalldatetime,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*3
	Task : Import member daily transaction from xml into table MemberDaily
	Author : Joseph@20130114
	DB: DB052.Affiliate_ZZun
	Original: [Aff_MemberDailyImportData]
	Revisions: 		
*/
BEGIN  
	SET NOCOUNT ON  

	-- check data is calculated for this month?

	if exists(select top(1) 1 from AffCommission (nolock) where DATEDIFF(m,@WinlostDate,Winlostdate)=0)
	   return

	Declare @SystemCurrency smallint

	Exec Aff_GetSystemCurrency @SystemCurrency = @SystemCurrency output


	DECLARE @TmpTable TABLE (UserName  VARCHAR(30), WinlostDate smalldatetime, ProductID tinyint)
	--Import new Data here
	DECLARE @TempTrans TABLE(
		UserName varchar(30),
		WinlostDate smalldatetime,
		ProductID tinyint,
		Turnover money,
		Outstanding money, 
		Winlost money,
		DrawGame money,	
		BetCount int,
		PlayerComm money,
		TurnoverNoDraw MONEY,
		BetCountNoDraw int);

	INSERT INTO @TempTrans 
	   (UserName ,
		WinlostDate,
		ProductID ,
		Turnover ,
		Outstanding , 
		Winlost,
		DrawGame,	
		BetCount,
		PlayerComm,
		TurnoverNoDraw,
		BetCountNoDraw)
	SELECT				
			[Table].[Column].value('./@username', 'varchar(30)') as [UserName],		
			[Table].[Column].value('./@winlostdate', 'smalldatetime') as [WinlostDate],
			[Table].[Column].value('./@productid', 'tinyint') as [ProductID],
			[Table].[Column].value('./@turnover', 'money') as [Turnover],
			[Table].[Column].value('./@outstanding', 'money') as [Outstanding],
			[Table].[Column].value('./@winloss', 'money') as [Winlost],
			[Table].[Column].value('./@drawgame', 'money') as [DrawGame],	
			[Table].[Column].value('./@betcount', 'int') as [betcount],
			[Table].[Column].value('./@playercomm', 'money') as [PlayerComm],
			[Table].[Column].value('./@turnovernodraw', 'money') as [TurnoverNoDraw],
			[Table].[Column].value('./@betcountnodraw', 'int') as [BetCountNoDraw]
		FROM @XmlData.nodes('/root/trans') as [Table]([Column]);

	DELETE MemberDaily
	WHERE WinlostDate = @WinlostDate

	INSERT INTO MemberDaily 
				([UserName]
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
			   ) 	
	SELECT t1.UserName, t1.WinlostDate, p.ProductID, t1.Turnover, t1.Outstanding, t1.Winlost, t1.DrawGame
		, mi.AffId
		, mi.IBCCustId
		, mi.Currency
		, ai.Currency
		, dbo.Aff_GetExchangeRate(mi.Currency, ai.Currency, @WinlostDate) as AffExRate
		, @SystemCurrency
		, dbo.Aff_GetExchangeRate(mi.Currency, @SystemCurrency, @WinlostDate) as SystemExRate
		,0 as Deposit
		,0 as Withdrawal
		,0 as Bonus
		,0 as Adjustment	
		,t1.BetCount
		,t1.PlayerComm
		,t1.BetCountNoDraw
		,t1.DrawGame
		,t1.TurnoverNoDraw
	FROM @TempTrans AS t1
		INNER JOIN MemberInfo AS mi ON t1.UserName = mi.UserName
		inner join affinfo as ai with (nolock) on mi.AffId = ai.AffId
		-- inner join Exchange as ex with (nolock) on ai.Currency = ex.ExchangeId
		inner join Product as p with (nolock) on t1.ProductID = p.API_ProductId
	where t1.WinlostDate=@WinlostDate and mi.IsRemoved = 0

END  