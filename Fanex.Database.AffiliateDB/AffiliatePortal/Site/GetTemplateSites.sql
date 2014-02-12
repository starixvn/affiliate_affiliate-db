 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetTemplateSites]    Script Date: 10/23/2010 10:08:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetTemplateSites]
	-- Add the parameters for the stored procedure here
	@takeCareValidSite bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    if @takeCareValidSite = 0
    begin
		select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
		from Sites
		left join Layouts as LB
		on Sites.bodyLayoutId = LB.layoutId
		left join Layouts as LF
		on Sites.footerLayoutId = LF.layoutId
		where siteId < 0
		order by siteId desc
	end
	else
	begin
		select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
		from Sites
		left join Layouts as LB
		on Sites.bodyLayoutId = LB.layoutId
		left join Layouts as LF
		on Sites.footerLayoutId = LF.layoutId
		where Sites.siteId < 0 and Sites.homePageId <> '00000000-0000-0000-0000-000000000000'
		order by siteId desc
	end
END
