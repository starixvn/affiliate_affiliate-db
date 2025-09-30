 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[CheckHasSite]    Script Date: 10/22/2010 10:24:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/19/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[CheckHasSite]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	select @siteId = siteId
	from Sites
	where siteId = @siteId
	
	select cast(@@rowcount as bit)
END
