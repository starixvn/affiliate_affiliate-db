 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[DeletePost]    Script Date: 10/22/2010 10:41:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/08/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DeletePost]
	-- Add the parameters for the stored procedure here
	@postId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	
    -- Insert statements for procedure here
	delete from Posts
	where postId = @postId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
	
	--update Taxonomy COUNT
	update Taxonomy
	set [count] = [count] - 1
	where taxonomyId in (select taxonomyId
						from TermRelationships
						where objectId = @postId)
	
	--delete relationship, keep categories + tags
	delete from TermRelationships
	where objectId = @postId and 
			taxonomyId in	(select taxonomyId
							from Taxonomy 
							where	Taxonomy.name = 'post_cat' or 
									Taxonomy.name = 'post_tag'
							)
	
	--3. child post
	delete from Posts
	where parentId = @postId
	
	select @result
END
