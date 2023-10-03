-- =============================================
-- Script Template
-- =============================================

set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Aff_BannerSelDetail_1]
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
FROM Banners_1 with (nolock)
WHERE BannerID=@BannerID      

GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail_1] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelDetail_1] TO [VNTeam]

