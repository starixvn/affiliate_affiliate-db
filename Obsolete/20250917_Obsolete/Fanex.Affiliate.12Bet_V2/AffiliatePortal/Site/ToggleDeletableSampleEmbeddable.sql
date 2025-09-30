set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

CREATE Procedure [dbo].[ToggleDeletableSampleEmbeddable]
	@embeddableId uniqueidentifier
AS
BEGIN
	SET NOCOUNT ON;
	update EmbeddableSamples
	set deletable = ~deletable
	where embeddableId = @embeddableId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END