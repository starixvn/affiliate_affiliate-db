 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[CheckWidgetBelongToSite]    Script Date: 10/22/2010 10:25:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[CheckWidgetBelongToSite]
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result int
    -- Insert statements for procedure here
	select @result = PageEmbeddables.instanceId
	from PageEmbeddables
	join Pages
	on PageEmbeddables.pageId = Pages.pageId
	where instanceId = @instanceId and Pages.siteId = @siteId
	
	if @result is null
		select cast(0 as bit)
	else
		select cast(1 as bit)
END
