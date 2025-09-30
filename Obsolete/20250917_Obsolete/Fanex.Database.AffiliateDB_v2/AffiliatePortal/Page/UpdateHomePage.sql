 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[UpdateHomePage]    Script Date: 10/23/2010 10:18:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateHomePage]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@homePageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update Sites
	set homePageId = @homePageId
	where siteId = @siteId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
