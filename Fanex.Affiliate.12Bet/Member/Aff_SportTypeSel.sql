Alter PROCEDURE [dbo].[Aff_SportTypeSel]
	
AS
/*
	Created: @VinhTrinh
	Task : Select Sport type
	DB: DB052.Affiliate_12BET	
	Revisions:	
*/
SET NOCOUNT ON
Select SportID, SportName
from SportType with(nolock)

GO
GRANT EXECUTE ON [dbo].[Aff_SportTypeSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SportTypeSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SportTypeSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SportTypeSel] TO [VNTeam]