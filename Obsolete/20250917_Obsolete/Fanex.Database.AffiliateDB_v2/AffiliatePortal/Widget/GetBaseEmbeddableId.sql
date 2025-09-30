 -- =============================================
-- Author:		Smith
-- Create date: 11/11/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBaseEmbeddableId]
	-- Add the parameters for the stored procedure here
	@embeddableId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select fromEmbeddableId
	from EmbeddableSamples (nolock)
	where embeddableId = @embeddableId
END
GO
