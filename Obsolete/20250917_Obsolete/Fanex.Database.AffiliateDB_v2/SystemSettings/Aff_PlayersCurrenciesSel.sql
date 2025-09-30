CREATE Procedure [dbo].[Aff_PlayersCurrenciesSel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AFF_PlayerCurrencies' and Type ='Meta')
	-- Insert statements for procedure here
	select CurrencyCode ,CurrencyID from Currency (nolock)
	where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END

GO
GRANT EXECUTE ON [dbo].[Aff_PlayersCurrenciesSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersCurrenciesSel] TO [vnteam]
  