ALTER PROCEDURE [dbo].[Aff_MinAmountSel]    
 @currencyName varchar(5)= 'US$',    
 @AFF_MinWire MONEY OUTPUT,    
 @AFF_MinNeteller MONEY OUTPUT,    
 @AFF_MinCheque MONEY OUTPUT,    
 @AFF_MinMoneybookers MONEY OUTPUT,    
 @AFF_MinPlayer MONEY = 0 OUTPUT    
AS    
/*  
 Created: 20090922@VinhTrinh  
 Task : Select minimum amount for payment request.  
 DB: DB052.Affiliate_ZZun  
*/  
SET NOCOUNT ON  
    
Select @AFF_MinWire = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinWire'+@currencyName    
Select @AFF_MinNeteller = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinNeteller'+@currencyName    
Select @AFF_MinCheque = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinCheque'+@currencyName     
Select @AFF_MinMoneybookers = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinMoneybookers'+@currencyName    
Select @AFF_MinPlayer = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinPlayer'+@currencyName  
GO
GRANT EXECUTE ON [dbo].[Aff_MinAmountSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_MinAmountSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_MinAmountSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MinAmountSel] TO [VNTeam]