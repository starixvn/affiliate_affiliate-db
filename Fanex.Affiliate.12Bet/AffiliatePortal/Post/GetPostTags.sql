 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[GetPostTags]    Script Date: 10/23/2010 10:07:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/16/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetPostTags]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select Terms.*
	from Terms
	join Taxonomy
	on Terms.termId = Taxonomy.termId
	where Terms.siteId = @siteId and Taxonomy.name = 'post_tag'
END
