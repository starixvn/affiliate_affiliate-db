set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


-- =============================================
-- Author:		Peter
-- Create date: 22-01-2013
-- Description:	Get System Currency Information
-- =============================================
ALTER PROCEDURE [dbo].[Aff_SystemCurrencySel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Code,Prefix, ExchangeID from Exchange (nolock)
	where Code = (select SValue from SystemSettings where SName = 'SystemCurrency')
END

GO

grant execute on  [dbo].[Aff_SystemCurrencySel] to [bodbAdminNet]

GO

grant view definition on  [dbo].[Aff_SystemCurrencySel] to [vnteam]