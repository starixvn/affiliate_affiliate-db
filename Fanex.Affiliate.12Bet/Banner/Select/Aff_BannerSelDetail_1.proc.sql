ALTER PROCEDURE [dbo].[Aff_BannerSelDetail_1] 
	@BannerID INT
AS
/*Created: 20090328@DungTong
Task : Get Specific baner information
DB:  DB052.Affiliate_12Bet

Revisions:
	- 20140226@Bobby: Apply AffType	
			  
Param's Explanation:
• @BannerID : ID of banner 
*/
BEGIN
	SET NOCOUNT ON

	SELECT BannerID
		,FileName
		,Category
		,[Language]
		,ImageType
		,[Size]
		,Lastupdate
		,Currency
		,AffType
	FROM Banners_1 WITH (NOLOCK)
	WHERE BannerID = @BannerID
END
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail_1] TO [bodbAdminNet]
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail_1] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail_1] TO [bodbDownlineNetView]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelDetail_1] TO [VNTeam]
