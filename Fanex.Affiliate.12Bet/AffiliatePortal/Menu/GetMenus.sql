 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[GetMenus]    Script Date: 10/23/2010 10:03:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/01/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetMenus] 
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT		Menu.*, Pages.title, Pages.url
	FROM		Menu LEFT JOIN
				Pages ON Menu.pageId = Pages.pageId
	WHERE		Menu.siteId = @siteId
END
