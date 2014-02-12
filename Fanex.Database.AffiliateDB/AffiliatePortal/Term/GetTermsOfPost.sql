 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetTermsOfPost]    Script Date: 10/23/2010 10:09:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetTermsOfPost] 
	-- Add the parameters for the stored procedure here
	@postId int,
	@taxonomy nvarchar(32)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select Terms.termId, Terms.name, Taxonomy.taxonomyId
	from Terms
	join Taxonomy on Terms.termId = Taxonomy.termId
	join TermRelationships on Taxonomy.taxonomyId = TermRelationships.taxonomyId
	where	TermRelationships.objectId = @postId
			and Taxonomy.name = @taxonomy
END
