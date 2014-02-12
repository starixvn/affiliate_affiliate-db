-- =============================================
-- Script Template
-- =============================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 19-02-2013
-- Description:	Get Affiliate Currencies Information
-- =============================================
ALTER Procedure [dbo].[Aff_AffiliateCurrenciesSel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AffiliateCurrencies' and Type ='Meta')
	-- Insert statements for procedure here
	select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID,MultipliedBy from Currency (nolock)
	where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END


GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCurrenciesSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCurrenciesSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCurrenciesSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateCurrenciesSel] TO [vnTeam]
GO