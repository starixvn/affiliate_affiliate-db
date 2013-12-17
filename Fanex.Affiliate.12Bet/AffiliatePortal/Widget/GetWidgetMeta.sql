USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[GetWidgetMeta]    Script Date: 10/23/2010 10:09:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/15/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetWidgetMeta]
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@isEmbeddableSample bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    if @isEmbeddableSample = 0
    begin
		select PageEmbeddables.title, PageEmbeddableMeta.[key],PageEmbeddableMeta.[value]
		from PageEmbeddables
		join PageEmbeddableMeta
		on PageEmbeddables.instanceId = PageEmbeddableMeta.instanceId
		where PageEmbeddables.instanceId = @instanceId
	end
	else
	begin
		select EmbeddableSamples.name as title, EmbeddableMeta.[key],EmbeddableMeta.[value]
		from EmbeddableSamples
		join EmbeddableMeta
		on EmbeddableSamples.embeddableId = EmbeddableMeta.embeddableId
		where EmbeddableSamples.embeddableId = @instanceId
	end
END
