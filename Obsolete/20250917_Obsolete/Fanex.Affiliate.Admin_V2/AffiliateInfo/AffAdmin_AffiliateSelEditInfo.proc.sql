ALTER Procedure [dbo].[AffAdmin_AffiliateSelEditInfo]
	@AffId int,
	@GetBalance bit = 0,
	@AFF_MinWire  MONEY = 0 OUTPUT,
	@Aff_MinNeteller MONEY = 0 OUTPUT,
	@AFF_MinCheque MONEY = 0 OUTPUT,
	@AFF_MinMoneybookers MONEY = 0 OUTPUT,
	@AFF_MinPlayer MONEY = 0 OUTPUT
AS
-- DB052.Affiliate_MYM
SET NOCOUNT ON
Declare @currencyName varchar(5)

Select @currencyName = Currency
from AffInfo with (nolock)
where AffId = @AffId

Select	@AFF_MinWire = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinWire'+@currencyName
Select	@Aff_MinNeteller = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinNeteller'+@currencyName
Select	@AFF_MinCheque = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinCheque'+@currencyName 
Select	@AFF_MinMoneybookers = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinMoneybookers'+@currencyName
Select	@AFF_MinPlayer = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinPlayer'+@currencyName

SELECT 	
	ai.AffId, 
	ai.username,	
	ai.username2,
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
	ad.countryID,	
	ad.SiteURL ,
	ad.MoreSiteURLs,
	ad.PreferredPayment, --Player, Neteller, Moneybookers, Wire, Cheque
	ad.PreferredLanguage,
	ai.Currency,
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
	ad.mailoption,
	--Do not allow edit when status is approved	
	(case when ai.Status in ('pending','disapproved') then 1 else 0 end) as IsCurrencyEditable
	--(case when ai.Status in ('pending','disapproved') or not exists (select top(1)  1 from Memberdaily (nolock) where AffID = ai.AffID ) then 1 else 0 end) as IsCurrencyEditable		
FROM 
	AffInfo ai with (nolock) 
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE 
	ai.AffId=@AffID
ORDER BY ai.username


