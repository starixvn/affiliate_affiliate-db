 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[InsertWidget]    Script Date: 10/23/2010 10:16:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertWidget]
	-- Add the parameters for the stored procedure here
	@embeddableId int,
	@bucket nvarchar(64),
	@pageId uniqueidentifier,
	@title nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @rootEmbeddableId int
	declare @isEmbeddableSample bit
	declare @instanceId int
	declare @orderNo int
	set @orderNo = dbo.GetMaxWidgetOrderNo(@pageId,@bucket) + 1
	
	if @embeddableId > 9999
	begin
		select @rootEmbeddableId = fromEmbeddableId
		from EmbeddableSamples
		where embeddableId = @embeddableId
		
		set @isEmbeddableSample = 1
	end
	else
	begin
		set @rootEmbeddableId = @embeddableId
		set @isEmbeddableSample = 0
	end
	
    -- Insert statements for procedure here
	insert into PageEmbeddables(pageId,bucket,embeddableId,title,[status],orderNo)
	values(@pageId,@bucket,@rootEmbeddableId,@title,0,@orderNo)
	
	IF @@ERROR <> 0
		set @instanceId = 0
	ELSE
		set @instanceId = cast(SCOPE_IDENTITY() as int)
	
	if @isEmbeddableSample = 1 and @instanceId <> 0
	begin
		--copy metadata from EmbeddableMeta -> PageEmbeddableMeta
		insert into PageEmbeddableMeta(instanceId,[key],value)
		select @instanceId,[key],value
		from EmbeddableMeta
		where EmbeddableMeta.embeddableId = @embeddableId
	end
	
	select @instanceId
END
