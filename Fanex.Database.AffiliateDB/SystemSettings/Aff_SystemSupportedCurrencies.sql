SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 19-02-2013
-- Description:	Get Affiliate System Supported Currencies Information
-- =============================================
ALTER Procedure [dbo].[Aff_SystemSupportedCurrencies] 
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AFF_SupportedCurrencies' and Type ='Meta')
	-- Insert statements for procedure here
	select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID,MultipliedBy from Currency (nolock)
	where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END



GO
GRANT EXECUTE ON [dbo].[Aff_SystemSupportedCurrencies] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSupportedCurrencies] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSupportedCurrencies] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSupportedCurrencies] TO [vnteam]