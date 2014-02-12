ALTER PROCEDURE [dbo].[Task_aff_DailyImportExchange]
	 @Date smalldatetime=null,
	 @Xml xml = null
AS
/*
	Created: 20110223@Peter
	Task : Import s from IBC
	DB: DB052.Affiliate_ZZun
	Revisions:
		- 20110223@Peter: initialize SP
		
*/
SET NOCOUNT ON


SELECT @Date = coalesce(CONVERT(varchar(10), @Date, 120),CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))

DECLARE @count int

DECLARE @TempTrans TABLE(
	ExchangeDate datetime,
	ExchangeID smallint,
	Code varchar(5),
	MYR float,
	USD float,
	EUR float,
	CNY float,
	SGD float,
	IDR float,
	AUD float,
	CHF float,
	GBP float,
	THB float,
	VND float
	)

insert into @TempTrans --Convert xml to table
Select	
		[Table].[Column].value('./@exchangedate', 'datetime') as ExchangeDate,	
		[Table].[Column].value('./@exchangeid', 'smallint') as ExchangeID,
		[Table].[Column].value('./@code', 'varchar(5)') as Code,
		[Table].[Column].value('./@myr', 'float') as MYR,		
		[Table].[Column].value('./@usd', 'float') as USD,				
		[Table].[Column].value('./@eur', 'float') as EUR,
		[Table].[Column].value('./@cny', 'float') as CNY,		
		[Table].[Column].value('./@sgd', 'float') as SGD,
		[Table].[Column].value('./@idr', 'float') as IDR,
		[Table].[Column].value('./@aud', 'float') as AUD,
		[Table].[Column].value('./@chf', 'float') as CHF,
		[Table].[Column].value('./@gbp', 'float') as GBP,
		[Table].[Column].value('./@thb', 'float') as THB,
		[Table].[Column].value('./@vnd', 'float') as VND

	from @Xml.nodes('/root/trans') as [Table]([Column])

update  @TempTrans

set  MYR=(case when code<>'MYR' then MYR/(select isnull(MultipliedBy,1) from Currency where currencycode='MYR') else MYR end)
      ,USD=(case when code<>'USD' then USD/(select isnull(MultipliedBy,1) from Currency where currencycode='USD') else USD end)
      ,EUR=(case when code<>'EUR' then EUR/(select isnull(MultipliedBy,1) from Currency where currencycode='EUR') else EUR end)
      ,CNY=(case when code<>'CNY' then CNY/(select isnull(MultipliedBy,1) from Currency where currencycode='CNY') else CNY end)
      ,IDR=(case when code<>'IDR' then IDR/(select isnull(MultipliedBy,1) from Currency where currencycode='IDR') else IDR end)
      ,AUD=(case when code<>'AUD' then AUD/(select isnull(MultipliedBy,1) from Currency where currencycode='AUD') else AUD end)
      ,CHF=(case when code<>'CHF' then CHF/(select isnull(MultipliedBy,1) from Currency where currencycode='CHF') else CHF end)
      ,GBP=(case when code<>'GBP' then GBP/(select isnull(MultipliedBy,1) from Currency where currencycode='GBP') else GBP end)
      ,SGD=(case when code<>'SGD' then SGD/(select isnull(MultipliedBy,1) from Currency where currencycode='SGD') else SGD end)
      ,THB=(case when code<>'THB' then THB/(select isnull(MultipliedBy,1) from Currency where currencycode='THB') else THB end)
      ,VND=(case when code<>'VND' then VND/(select isnull(MultipliedBy,1) from Currency where currencycode='VND') else VND end)


UPDATE ec
SET  USD = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.USD,ec.USD,0) ELSE ec.USD END)
	,USD_Market = coalesce(ed.usd,ec.USD_Market,0)
	,EUR = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.EUR,ec.EUR,0) ELSE ec.EUR END)
	,EUR_Market = coalesce(ed.EUR,ec.EUR_Market,0)
	,CNY = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.CNY,ec.CNY,0) ELSE ec.CNY END)
	,CNY_Market = coalesce(ed.CNY,ec.CNY_Market,0)
	,UUS = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.UUS END)
	,UUS_Market = 2E-102
	,MYR = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.MYR,ec.MYR,0) ELSE ec.MYR END)
	,MYR_Market = coalesce(ed.MYR,ec.MYR_Market,0)
	,SGD = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.SGD,ec.SGD,0) ELSE ec.SGD END)
	,SGD_Market = coalesce(ed.SGD,ec.SGD_Market,0)
	,IDR = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.IDR,ec.IDR,0) ELSE ec.IDR END)
	,IDR_Market = coalesce(ed.IDR,ec.IDR_Market,0)
	,AUD = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.AUD,ec.AUD,0) ELSE ec.AUD END)
	,AUD_Market = coalesce(ed.AUD,ec.AUD_Market,0)
	,CHF = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.CHF,ec.CHF,0) ELSE ec.CHF END)
	,CHF_Market = coalesce(ed.CHF,ec.CHF_Market,0)
	,GBP = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.GBP,ec.GBP,0) ELSE ec.GBP END)
	,GBP_Market = coalesce(ed.GBP,ec.GBP_Market,0)
	,THB = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.THB,ec.THB,0) ELSE ec.THB END)
	,THB_Market = coalesce(ed.THB,ec.THB_Market,0)
	,VND = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.VND,ec.VND,0) ELSE ec.VND END)
	,VND_Market = coalesce(ed.VND,ec.VND_Market,0)
FROM Exchange ec with(rowlock, updlock)	
	INNER JOIN dbo.CurrencyConverter cc with(nolock) on ec.ExchangeID = cc.ExchangeID
	INNER JOIN @TempTrans as ed on ed.ExchangeID = cc.PartnerExchangeID
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
FROM Exchange ec with(rowlock, updlock)		
WHERE ExchangeID = 9999





if @@ROWCOUNT = 0  
 PRINT 'No data available for this day!'

DELETE ExchangeDaily
WHERE [Date] = @date

INSERT INTO ExchangeDaily (Date, ExchangeID,USD,USD_Market,EUR,EUR_Market,CNY,CNY_Market,UUS,UUS_Market,MYR,MYR_Market,SGD,SGD_Market,IDR,IDR_Market,AUD,AUD_Market,CHF,CHF_Market,GBP,GBP_Market,THB,THB_Market,VND,VND_Market,Code,DepositPercent,WithdrawalPercent,IsAutoRefresh)
SELECT @date,  ExchangeID,USD,USD_Market,EUR,EUR_Market,CNY,CNY_Market,UUS,UUS_Market,MYR,MYR_Market,SGD,SGD_Market,IDR,IDR_Market,AUD,AUD_Market,CHF,CHF_Market,GBP,GBP_Market,THB,THB_Market,VND,VND_Market,Code,DepositPercent,WithdrawalPercent,IsAutoRefresh
FROM Exchange with(nolock)

-- if the date < current_date and date > max(winlostdate from commission)
-- update all data for MemberDaily,MemberDailyRemoved, AffDaily,AffDailySummary

declare @TaskID int,@LogID int , @RunDate datetime, @Status varchar(50)

select @RunDate=getdate(), @Status='completed'

select @TaskID= TaskID from TaskManager(nolock) where TaskName='Import Exchange Daily'
exec [dbo].[Aff_TaskLogIns]
	@TaskID,
	@RunDate,
	@Status,
	@LogID OUTPUT



GO
GRANT VIEW DEFINITION ON [dbo].[Task_aff_DailyImportExchange] TO [VNTeam]