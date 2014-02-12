 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[DeletePage]    Script Date: 10/22/2010 10:40:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith Tran
-- Create date: 3:29 PM 9/21/2010
-- Description:	Delete page and related data
-- =============================================
ALTER PROCEDURE [dbo].[DeletePage]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	
    -- delete page
	delete from Pages
	where pageId = @pageId
	
	set @result = cast(@@rowcount as bit)
	
	-- update master page
	update Pages
	set masterId = null
	where masterId = @pageId
	
	-- update menu
	update Menu
	set pageId = null
	where pageId = @pageId
	
	-- delete AliasURLs
	delete from AliasURLs
	where pageId = @pageId
	
	-- delete PageEmbeddableMeta
	delete from PageEmbeddableMeta
	where instanceId in (	select instanceId
							from PageEmbeddables
							where pageId = @pageId)
	
	-- delete PageEmbeddables
	delete from PageEmbeddables
	where pageId = @pageId
	
	-- delete SEOMetaData
	delete from SEOMetaData
	where pageId = @pageId
	
	select @result
END
