ALTER PROCEDURE [dbo].[Aff_BannerSelDetail]
	@BannerID int
AS

/*Created: 20090328@DungTong
Task : Get Specific baner information
DB:  DB052.Affiliate_12Bet

Revisions:    	
			  
Param's Explanation:
• @BannerID : ID of banner 
*/

SET NOCOUNT ON
  
SELECT BannerID, FileName, Category,
			[Language], ImageType, [Size],Lastupdate,Currency
FROM Banners with (nolock)
WHERE BannerID=@BannerID      


GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelDetail] TO [VNTeam]

