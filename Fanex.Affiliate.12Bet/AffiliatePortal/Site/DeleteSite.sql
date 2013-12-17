 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[DeleteSite]    Script Date: 10/22/2010 10:42:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/06/2010
-- Update data: 10/06/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DeleteSite]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	delete from Sites
	where siteId = @siteId
	
	--delete related data
	--TODO:
	
	select cast(@@rowcount as bit)
END
