  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from ClickStatistics_bk with (nolock))
  begin
      truncate table ClickStatistics_bk
  end
  
-- ClickStatistics_bk
INSERT INTO ClickStatistics_bk (
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
from DB03.[12BetAffiliate].dbo.Affiliate_ClickStatistics_bk with (nolock)	
GO