  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from Exchange_Current with (nolock))
  begin
      truncate table Exchange_Current
  end
  
-- Exchange_Current
INSERT INTO Exchange_Current (
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
)
SELECT 
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
from DB03.[12BetAffiliate].dbo.Affiliate_Exchange_Current with(nolock)
GO