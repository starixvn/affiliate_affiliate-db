  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from Exchange with (nolock))
  begin
      truncate table Exchange
  end
  
  -- Exchange
INSERT INTO Exchange (
	UpdatedTime,
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
)
SELECT 
	UpdateTime,
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
from DB03.[12BetAffiliate].dbo.Affiliate_Exchange with (nolock)
GO