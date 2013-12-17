  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from ClickStatisticsSum with (nolock))
  begin
      truncate table ClickStatisticsSum
  end
  
-- ClickStatisticsSum
INSERT INTO ClickStatisticsSum (
	AffId,
	TrackingID,
	Date,
	IsForMonth,
	TotalClick,
	UniqueClick
)
SELECT 
	AffiliateID,
	TrackingID,
	Date,
	IsForMonth,
	TotalClick,
	UniqueClick
from DB03.[12BetAffiliate].dbo.Affiliate_ClickStatisticsSum	with (nolock) 
GO