 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetSiteBySiteId]    Script Date: 10/23/2010 10:08:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetSiteBySiteId]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
	from Sites
	left join Layouts as LB
	on Sites.bodyLayoutId = LB.layoutId
	left join Layouts as LF
	on Sites.footerLayoutId = LF.layoutId
	where siteId = @siteId
END
