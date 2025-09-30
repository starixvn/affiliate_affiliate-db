 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetPostCategoryWithCount]    Script Date: 10/23/2010 10:06:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetPostCategoryWithCount]
	-- Add the parameters for the stored procedure here
	@siteId int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Terms.*, Taxonomy.[count] as [count]
	from Terms
	join Taxonomy
	on Terms.termId = Taxonomy.termId
	where siteId = @siteId and Taxonomy.name = 'post_cat'
END
