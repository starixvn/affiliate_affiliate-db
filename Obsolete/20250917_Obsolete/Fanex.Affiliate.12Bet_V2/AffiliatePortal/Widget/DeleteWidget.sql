 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[DeleteWidget]    Script Date: 10/22/2010 11:02:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DeleteWidget]
	-- Add the parameters for the stored procedure here
	@instanceId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	declare @pageId uniqueidentifier
	declare @bucket nvarchar(64)
	declare @orderNo int
	
	-- Get current widget
	select @pageId = pageId, @bucket = bucket, @orderNo = orderNo
	from PageEmbeddables
	where  instanceId = @instanceId
	
    -- Insert statements for procedure here
	delete from PageEmbeddables
	where instanceId = @instanceId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
	
	--update order
	if( @result = 1)
	begin
		update PageEmbeddables
		set orderNo = orderNo - 1
		where pageId = @pageId and bucket = @bucket and orderNo > @orderNo
	end
	
	--delete related data
	delete from PageEmbeddableMeta
	where instanceId = @instanceId
	
	select @result
END
