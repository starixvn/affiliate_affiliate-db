 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetBasicSetting]    Script Date: 10/22/2010 13:47:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/12/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetBasicSetting]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT siteName,siteTitle,siteHost,displayName
	FROM Sites
	WHERE siteId = @siteId
END
