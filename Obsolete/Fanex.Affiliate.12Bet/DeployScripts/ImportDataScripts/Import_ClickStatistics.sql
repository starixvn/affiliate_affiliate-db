  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from ClickStatistics with (nolock))
  begin
      truncate table ClickStatistics
  end
  

-- ClickStatistics
INSERT INTO ClickStatistics (
	TrackingID,
	UpdatedTime,
	IP,
	Date,
	Browser,
	URLReferrer
)
SELECT 
	TrackingID,
	UpdateTime,
	IP,
	Date,
	Browser,
	URLReferrer
from DB03.[12BetAffiliate].dbo.Affiliate_ClickStatistics	
GO