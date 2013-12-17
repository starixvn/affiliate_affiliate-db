Alter PROCEDURE [dbo].[Aff_AffiliateSelEditInfo]
	@AffId int,
	@GetBalance bit = 0,
	@AFF_MinWire  MONEY = 0 OUTPUT,
	@Aff_MinNeteller MONEY = 0 OUTPUT,
	@AFF_MinCheque MONEY = 0 OUTPUT,
	@AFF_MinMoneybookers MONEY = 0 OUTPUT,
	@AFF_MinPlayer MONEY = 0 OUTPUT
AS
-- DB052.Affiliate_12BET
SET NOCOUNT ON
Declare @currencyName varchar(5)

Select @currencyName = e.Currency
from Exchange_Current e with (nolock)--Get currency name of affiliate
	inner join AffInfo a with (nolock) on a.Currency = e.ExchangeId
where a.AffId = @AffId

Select	@AFF_MinWire = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinWire'+@currencyName
Select	@Aff_MinNeteller = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinNeteller'+@currencyName
Select	@AFF_MinCheque = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinCheque'+@currencyName 
Select	@AFF_MinMoneybookers = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinMoneybookers'+@currencyName
Select	@AFF_MinPlayer = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinPlayer'+@currencyName

SELECT 	
	ai.AffId, 
	ai.username,	
	ad.gender,
	ai.firstname,
	ai.lastname,
	ai.Status,
	ai.email,
	ad.phone,
	ad.mobilephone,
	ad.address,
	ad.city,
	ad.state,
	ad.postal,
	ad.country,	
	ad.SiteURL ,
	ad.MoreSiteURLs,
	ad.NoSiteDesc,
	ad.PreferredPayment, --Player, Neteller, Moneybookers, Wire, Cheque
	ad.PreferredLanguage,
	ad.Player_Username,
	ad.Neteller_AccountID,
	ad.Moneybookers_Email,
	ad.Wire_BankName,
	ad.Wire_BankAddress,
	ad.Wire_SwiftCode,
	ad.Wire_AccountName,	
	ad.Wire_AccountNo,
	ad.Cheque_FullName,
	ad.Cheque_Address,
	ad.Cheque_City,
	ad.Cheque_State,
	ad.Cheque_Postal,
	ad.Cheque_Country,
	ad.question,
	ad.answer,
	ad.mailoption		
FROM 
	AffInfo ai with (nolock) 
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE 
	ai.AffId=@AffID
ORDER BY ai.username

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelEditInfo] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelEditInfo] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelEditInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelEditInfo] TO [VNTeam]