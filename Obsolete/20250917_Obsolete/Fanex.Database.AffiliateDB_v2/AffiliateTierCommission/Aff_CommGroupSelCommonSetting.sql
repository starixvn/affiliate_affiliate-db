USE [Affiliate_Athena000]
GO
  
ALTER PROCEDURE [Aff_CommGroupSelCommonSetting]
AS  

/*  
	Created: 20090719@DungTong
	Task: Get Common Setting for Adding or Editing new Group
	DB: DBAFF.Affiliate_Athena000  
	Original:
  
	Revisions:
*/

BEGIN  
	SET NOCOUNT ON
	
	select ProductID, ProductName  
	from Product (nolock)
   
	select DTypeID, ProductID, DTypeName, DTypeDesc, DeductedPercentage   
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
GO