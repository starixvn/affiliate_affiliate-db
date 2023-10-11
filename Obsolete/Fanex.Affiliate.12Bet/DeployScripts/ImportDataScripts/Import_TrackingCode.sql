  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from TrackingCode with (nolock))
  begin
      truncate table TrackingCode
  end
  

-- Tracking Code
SET IDENTITY_INSERT TrackingCode ON
GO
INSERT INTO TrackingCode (
	TrackingID,
	AffID,
	TrackingCode,
	CreatedDate,
	IP
)
SELECT 
	TrackingID,
	AffiliateID,
	TrackingCode,
	CreateDate,
	IP
from DB03.[12BetAffiliate].dbo.Affiliate_TrackingCode with (nolock)	
GO
SET IDENTITY_INSERT TrackingCode OFF
GO	
