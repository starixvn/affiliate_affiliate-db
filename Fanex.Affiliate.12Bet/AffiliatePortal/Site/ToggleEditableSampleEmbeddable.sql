set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER Procedure [dbo].[ToggleEditableSampleEmbeddable]
	@embeddableId uniqueidentifier
AS
BEGIN
	SET NOCOUNT ON;
	update EmbeddableSamples
	set editable = ~editable
	where embeddableId = @embeddableId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END