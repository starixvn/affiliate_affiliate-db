 -- =============================================
-- Author:		Smith
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetAllEmbeddableSamples]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select EmbeddableSamples.*, Embeddables.name as baseEmbeddable
	from EmbeddableSamples (nolock)
	inner join Embeddables (nolock)
	on EmbeddableSamples.fromEmbeddableId = Embeddables.embeddableId
END
GO
