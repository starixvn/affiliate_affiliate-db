Alter PROCEDURE [dbo].[Aff_ProductSel]
	
AS
/*
	Created: @VinhTrinh
	Task : Select Product list
	DB: DB052.Affiliate_ZZun	
	Revisions:	
*/
SET NOCOUNT ON
Select ProductID, ProductName
from Product with(nolock)

GO
GRANT EXECUTE ON [dbo].[Aff_ProductSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ProductSel] TO [VNTeam]
