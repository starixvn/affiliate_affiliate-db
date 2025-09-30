set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

-- =============================================
-- Author:		Peter
-- Create date: 19-02-2013
-- Description:	Get Affiliate Currencies Information
-- =============================================
CREATE Procedure [dbo].[Aff_SystemSupportedCurrencies] 
		
AS
BEGIN
	
	SET NOCOUNT ON;

	declare @Currencies varchar(max)
	select @Currencies=(select SValue from SystemSettings where SName = 'AFF_SupportedCurrencies' and Type ='Meta')
	-- Insert statements for procedure here
	select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID from Currency (nolock)
	where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )

END


GO

GRANT EXECUTE ON [dbo].[Aff_SystemSupportedCurrencies] to [bodbAdminNet]

GO

GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSupportedCurrencies] to [vnteam]


