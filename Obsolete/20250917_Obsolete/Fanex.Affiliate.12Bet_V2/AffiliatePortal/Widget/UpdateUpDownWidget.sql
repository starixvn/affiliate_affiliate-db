 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[UpdateUpDownWidget]    Script Date: 10/23/2010 10:22:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateUpDownWidget]
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@up bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @pageId uniqueidentifier
	declare @bucket nvarchar(64)
	declare @orderNo int
	
    -- Get current widget
	select @pageId = pageId, @bucket = bucket, @orderNo = orderNo
	from PageEmbeddables
	where  instanceId = @instanceId
	
	if @up = 1 and @orderNo > 0
	begin
		-- move up
		update PageEmbeddables
		set orderNO = orderNO + 1
		where pageId = @pageId and bucket = @bucket and orderNo = (@orderNo - 1)
		
		update PageEmbeddables
		set orderNO = orderNO - 1
		where instanceId = @instanceId
	end
	
	else begin
		-- move down
		update PageEmbeddables
		set orderNO = orderNO - 1
		where pageId = @pageId and bucket = @bucket and orderNo = (@orderNo + 1)
		
		update PageEmbeddables
		set orderNO = orderNO + 1
		where instanceId = @instanceId
	end
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)	
END
