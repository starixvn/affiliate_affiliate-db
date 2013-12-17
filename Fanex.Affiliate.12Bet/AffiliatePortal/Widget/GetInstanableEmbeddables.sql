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
	select PageEmbeddables.*, Embeddables.name as embeddableName, Embeddables.editable as editable, cast(1 as bit) as deletable
	from PageEmbeddables  (nolock)
	inner join Embeddables (nolock) on PageEmbeddables.embeddableId = Embeddables.embeddableId
	
	where pageId = @pageId
	order by bucket desc, orderNo asc
END
GO
