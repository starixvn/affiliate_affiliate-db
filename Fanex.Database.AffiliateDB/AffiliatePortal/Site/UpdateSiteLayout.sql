 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[UpdateSiteLayout]    Script Date: 10/23/2010 10:21:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/15/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateSiteLayout]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@bodyLayoutId int,
	@footerLayoutId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --todo
    --1. update Sites tables (bodyLayoutId, footerLayoutId)
    --2. update widget(an instance of embeddable)
    --      + if new layout have no it's bucket, move it to another 'meaning bucket'
	--		+ update orderNo of new bucket it moved (1,2,3...)
	
	-- in this Portal, we have:
	--		+ 8 body layouts
	--		+ 3 footer layouts
	
	--return true
	select convert(bit,1)
END
