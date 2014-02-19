USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ExchangeDailyOanda_SelByDate]    Script Date: 02/18/2014 00:57:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Aff_ExchangeDailyOanda_SelByDate]
	 @Date smalldatetime=null
AS
/*	
	Created: 20130426@Peter
	Date: 2013-03-15
	Task: get exchange daily for AFF service
	DB: DBACC/bodb02
	
	Revisions:
		- 20140218@Dan: add currency KRW, JPY
		
*/
SET NOCOUNT ON

IF @Date is null 
SELECT @Date = coalesce(CONVERT(varchar(10), @Date, 120),CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))


DECLARE @Exchange TABLE (ExchangeDate smalldatetime,ExchangeID int, code varchar(8), MYR float,USD float, EUR float, CNY float, IDR float,AUD float, CHF float, GBP float, SGD float, THB float, VND float, KRW float, JPY float)

INSERT INTO @Exchange(ExchangeDate,ExchangeID, code, MYR,USD, EUR, CNY, IDR,AUD, CHF, GBP, SGD, THB, VND, KRW, JPY)
select ExchangeDate,ed.ExchangeID, ed.code, MYR,USD, EUR, CNY, IDR,AUD, CHF, GBP, SGD, THB, VND, KRW, JPY
from dbo.exchangedailyoanda ed with(nolock)
	inner join
	(
		select code,min(exchangeID) as exchangeID from Exchange (nolock)

		where code in
		(
			select distinct Code from exchangedailyoanda (nolock) where exchangedate=@Date
		)
		group by code

	) et on et.exchangeid=ed.exchangeid
WHERE exchangedate = @Date

order by ed.exchangeid

declare @BaseCurrencies table (code varchar(5), multipliedBy float)

insert into @BaseCurrencies(code,multipliedBy)
select code,(case when code='USD' then USD 
             when code='MYR' then MYR
             when code='EUR' then EUR
             when code='CNY' then CNY
             when code='IDR' then IDR 
             when code='AUD' then AUD 
             when code='CHF' then CHF 
             when code='GBP' then GBP 
             when code='SGD' then SGD 
             when code='THB' then THB 
             when code='VND' then VND              
             when code='KRW' then KRW 
             when code='JPY' then JPY 
            
       else 1 end) as multipliedBy

from @Exchange

where code in ('MYR','USD', 'EUR', 'CNY', 'IDR','AUD', 'CHF', 'GBP', 'SGD', 'THB', 'VND', 'KRW', 'JPY')

select ExchangeDate,ExchangeID, code
      ,(case when code='MYR' then MYR/(select multipliedBy from @BaseCurrencies where code='MYR') else MYR end) as MYR
      ,(case when code='USD' then USD/(select multipliedBy from @BaseCurrencies where code='USD') else USD end) as USD
      ,(case when code='EUR' then EUR/(select multipliedBy from @BaseCurrencies where code='EUR') else EUR end) as EUR
      ,(case when code='CNY' then CNY/(select multipliedBy from @BaseCurrencies where code='CNY') else CNY end) as CNY
      ,(case when code='IDR' then IDR/(select multipliedBy from @BaseCurrencies where code='IDR') else IDR end) as IDR
      ,(case when code='AUD' then AUD/(select multipliedBy from @BaseCurrencies where code='AUD') else AUD end) as AUD
      ,(case when code='CHF' then CHF/(select multipliedBy from @BaseCurrencies where code='CHF') else CHF end) as CHF
      ,(case when code='GBP' then GBP/(select multipliedBy from @BaseCurrencies where code='GBP') else GBP end) as GBP
      ,(case when code='SGD' then SGD/(select multipliedBy from @BaseCurrencies where code='SGD') else SGD end) as SGD
      ,(case when code='THB' then THB/(select multipliedBy from @BaseCurrencies where code='THB') else THB end) as THB
      ,(case when code='VND' then VND/(select multipliedBy from @BaseCurrencies where code='VND') else VND end) as VND
      ,(case when code='KRW' then KRW/(select multipliedBy from @BaseCurrencies where code='KRW') else KRW end) as KRW
      ,(case when code='JPY' then JPY/(select multipliedBy from @BaseCurrencies where code='JPY') else JPY end) as JPY
from  @Exchange       



GO

GRANT EXECUTE ON [dbo].[Aff_ExchangeDailyOanda_SelByDate] TO [bodbAdminNet]

GO

GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeDailyOanda_SelByDate] TO [vnteam]