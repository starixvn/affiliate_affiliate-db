ALTER PROCEDURE [dbo].[Aff_BannerSelDetail]
	@BannerID int
AS

/*Created: 20090328@DungTong
Task : Get Specific baner information
DB:  DB052.Affiliate_ZZun

Revisions:    	
              
Param's Explanation:
• @BannerID : ID of banner 
*/

SET NOCOUNT ON
  
SELECT BannerID, Content, Category,bt.parentID as ParentID,
			[Language], ImageType, [Size],Lastupdate,Currency,b.Type,Version,TotalRequest,LastRequest
FROM Banners b with (nolock)
inner join BannerTypes bt (nolock) on bt.TypeID=b.Category
WHERE BannerID=@BannerID




GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelDetail] TO [VNTeam]

