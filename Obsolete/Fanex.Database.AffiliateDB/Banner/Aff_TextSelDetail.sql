USE Affiliate_ZZun
GO
/****** Object:  StoredProcedure [dbo].[Aff_TextSelDetail_1]    Script Date: 01/29/2013 16:52:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TextSelDetail_1_xpre    Script Date: 4/3/2012 3:07:14 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextSelDetail_1    Script Date: 2/24/2012 10:17:35 AM ******/

CREATE PROCEDURE [dbo].[Aff_TextSelDetail]
	@TextID int
AS

SET NOCOUNT ON
  
SELECT BannerID, Category,
			[Language],Lastupdate,Currency,[Message]
FROM Banners with (nolock)
WHERE BannerID=@TextID