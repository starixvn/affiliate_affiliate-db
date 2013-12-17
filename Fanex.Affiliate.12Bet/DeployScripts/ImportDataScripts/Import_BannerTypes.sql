   USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from BannerTypes with (nolock))
  begin
      truncate table BannerTypes
  end
  
-- BannerTypes
INSERT INTO BannerTypes (
	Type,
	Value,
	DisplayOrder
)
SELECT 
	Type,
	Value,
	DisplayOrder
from DB03.[12BetAffiliate].dbo.Affiliate_BannerTypes	
GO

Select * from BannerTypes