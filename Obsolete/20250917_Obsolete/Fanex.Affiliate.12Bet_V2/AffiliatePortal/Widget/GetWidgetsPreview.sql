 -- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetWidgetsPreview]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    select * from
	(
		select PageEmbeddableTemps.*, Embeddables.name as embeddableName, Embeddables.editable as editable, cast(1 as bit) as deletable
		from PageEmbeddableTemps  (nolock)
		inner join Embeddables (nolock) on PageEmbeddableTemps.embeddableId = Embeddables.embeddableId
		
		union all
		
		select PageEmbeddableTemps.*, EmbeddableSamples.name as embeddableName, EmbeddableSamples.editable as editable, EmbeddableSamples.deletable
		from PageEmbeddableTemps  (nolock)
		inner join EmbeddableSamples (nolock) on PageEmbeddableTemps.embeddableId = EmbeddableSamples.embeddableId
	) alias

	where pageId = @pageId
	order by bucket desc, orderNo asc
END
GO