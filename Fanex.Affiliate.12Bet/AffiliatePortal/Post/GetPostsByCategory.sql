 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[GetPostsByCategory]    Script Date: 10/23/2010 10:06:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetPostsByCategory]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@categoryId int,
	@pageNumber int,
	@pageSite int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @commentNumber int
	set @commentNumber = 0
    -- Insert statements for procedure here
	select Posts.*,@commentNumber as commentNumber from Posts
	join TermRelationships
	on Posts.postId = TermRelationships.objectId
	join Taxonomy
	on TermRelationships.taxonomyId = Taxonomy.taxonomyId
	where Posts.siteId = @siteId and Taxonomy.termId = @categoryId
	order by postId desc
END
