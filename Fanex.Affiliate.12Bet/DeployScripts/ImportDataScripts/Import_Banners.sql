  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from Banners with (nolock))
  begin
      truncate table Banners
  end
  
-- Banners
SET IDENTITY_INSERT Banners ON
GO
INSERT INTO Banners (
	BannerID,
	FileName,
	Category,
	Language,
	ImageType,
	Size,
	LastUpdate,
	Currency,
	CreatedDate,
	UpdatedBy,
	Creator
)
SELECT 
	BannerID,
	FileName,
	Category,
	Language,
	ImageType,
	Size,
	LastUpdate,
	Currency,
	CreateDate,
	UpdatedBy,
	Creator
from DB03.[12BetAffiliate].dbo.Affiliate_banners	
GO
SET IDENTITY_INSERT Banners OFF
GO	