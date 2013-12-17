 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[UpdateSite]    Script Date: 10/23/2010 10:20:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/06/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateSite]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@siteName nvarchar(256),
	@siteHost nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update Sites
	set siteName = @siteName, siteHost = @siteHost
	where siteId = @siteId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
