 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[GetWidgets]    Script Date: 10/23/2010 10:10:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetWidgets]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select PageEmbeddables.*, Embeddables.name as embeddableName, Embeddables.editable as editable
	from PageEmbeddables 
	join Embeddables on PageEmbeddables.embeddableId = Embeddables.embeddableId
	
	where pageId = @pageId
	order by bucket asc, orderNo asc
END
