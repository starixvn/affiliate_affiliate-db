set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


-- =============================================
-- Author:		Peter
-- Create date: 22-01-2013
-- Description:	Get Base Currencies Information
-- =============================================
ALTER PROCEDURE [dbo].[Aff_BaseCurrenciesSel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @SupportedBaseCurrencies varchar(max)
    select @SupportedBaseCurrencies=(select SValue from SystemSettings where SName = 'SupportedBaseCurrencies')
	-- Insert statements for procedure here
	select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID,MultipliedBy from Currency (nolock)
	where CurrencyCode in (select val from [dbo].[strSplit] ( @SupportedBaseCurrencies, ',' ) )



END




GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrenciesSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrenciesSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrenciesSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BaseCurrenciesSel] TO [VNTeam]
