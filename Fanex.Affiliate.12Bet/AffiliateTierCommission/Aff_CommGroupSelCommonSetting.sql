USE [Affiliate_12BET]
GO

ALTER PROCEDURE [Aff_CommGroupSelCommonSetting]	
AS

/*
	Created: 20090719@DungTong
	Task: Get Common Setting for Adding or Editing new Group
	DB: DB052.Affiliate_12Bet
	Original:

	Revisions:
*/

BEGIN
	SET NOCOUNT ON
	Select SportID, SportName
	from SportType (nolock)
	
	Select DTypeID, SportID,DTypeName, DTypeDesc, DeductedPercentage 
	from DeductionType (nolock)
	
END
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelCommonSetting] TO [vnteam]
