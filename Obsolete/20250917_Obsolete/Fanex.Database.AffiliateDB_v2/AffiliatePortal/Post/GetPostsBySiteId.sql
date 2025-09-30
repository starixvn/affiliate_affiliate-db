 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetPostsBySiteId]    Script Date: 10/23/2010 10:07:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetPostsBySiteId]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@pageNumber int,
	@pageSite int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @commentNumber int
	set @commentNumber = 0
    -- Insert statements for procedure here
	select *,@commentNumber as commentNumber from Posts
	where siteId = @siteId
	order by postId desc
END
