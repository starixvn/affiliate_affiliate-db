USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ExchangeDailyOanda_SelByDate]    Script Date: 06/10/2013 05:11:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Aff_ExchangeDailyOanda_SelByDate]
	 @Date smalldatetime=null
AS
/*
	Created: 20130426@Peter
	Revisions:
		
*/
SET NOCOUNT ON

if @Date is null 
SELECT @Date = coalesce(CONVERT(varchar(10), @Date, 120),CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))


declare @Exchange table (ExchangeDate smalldatetime,ExchangeID int, code varchar(8), MYR float,USD float, EUR float, CNY float, IDR float,AUD float, CHF float, GBP float, SGD float, THB float, VND float)

insert into @Exchange(ExchangeDate,ExchangeID, code, MYR,USD, EUR, CNY, IDR,AUD, CHF, GBP, SGD, THB, VND)
select ExchangeDate,ed.ExchangeID, ed.code, MYR,USD, EUR, CNY, IDR,AUD, CHF, GBP, SGD, THB, VND
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
            
       else 1 end) as multipliedBy

from @Exchange

where code in ('MYR','USD', 'EUR', 'CNY', 'IDR','AUD', 'CHF', 'GBP', 'SGD', 'THB', 'VND')

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
from  @Exchange       


   

GO

GRANT EXECUTE ON [dbo].[Aff_ExchangeDailyOanda_SelByDate] TO [bodbAdminNet]

GO

GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeDailyOanda_SelByDate] TO [vnteam]