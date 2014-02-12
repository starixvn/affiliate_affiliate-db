USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateForgotPwd]    Script Date: 04/04/2013 14:49:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_AffSelDetail]
	@AffID int
AS
SET NOCOUNT ON

select * from AffDetail where AffID = @AffID




GO
GRANT EXECUTE ON [dbo].[Aff_AffSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffSelDetail] TO [vnteam]
GO
