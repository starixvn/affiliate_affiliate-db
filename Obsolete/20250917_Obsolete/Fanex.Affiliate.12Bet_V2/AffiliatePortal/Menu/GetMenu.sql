 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[GetMenu]    Script Date: 10/23/2010 10:02:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetMenu]
	-- Add the parameters for the stored procedure here
	@menuId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT		Menu.*, Pages.title, Pages.url
	FROM		Menu LEFT JOIN
				Pages ON Menu.pageId = Pages.pageId
	WHERE		Menu.menuId = @menuId
END
