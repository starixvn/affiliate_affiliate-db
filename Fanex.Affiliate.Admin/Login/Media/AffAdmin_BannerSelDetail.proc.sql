CREATE PROCEDURE [dbo].[AffAdmin_BannerSelDetail]
	@BannerID int
AS

/*Created: 20090328@DungTong
Task : Get Specific baner information
DB:  DB052.Affiliate_MYM

Revisions:    	
              
Param's Explanation:
• @BannerID : ID of banner 
*/

SET NOCOUNT ON

SELECT
	BannerID,
	Content,
	Category,
	bt.parentID AS ParentID,
	[Language],
	ImageType,
	[Size],
	Lastupdate,
	Currency,
	b.Type,
	Version,
	TotalRequest,
	LastRequest
FROM Banners b WITH (NOLOCK)
INNER JOIN BannerTypes bt (NOLOCK)
	ON bt.TypeID = b.Category
WHERE BannerID = @BannerID

GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_BannerSelDetail] TO [vnteam]