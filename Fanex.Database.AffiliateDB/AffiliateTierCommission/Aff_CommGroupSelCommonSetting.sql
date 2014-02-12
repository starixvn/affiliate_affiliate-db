ALTER Procedure [Aff_CommGroupSelCommonSetting]   
AS  
/*  
Created: 20090719@DungTong  
Task : Get Common Setting for Adding or Editing new Group  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
*/  
SET NOCOUNT ON  
 Select top(1000) ProductID,ProductName  
 from Product (nolock)  
   
 Select top(100)  DTypeID,ProductID,DTypeName,DTypeDesc,DeductedPercentage   
 from DeductionType (nolock)  
   
  

GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelCommonSetting] TO [vnteam]
