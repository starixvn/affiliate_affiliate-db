 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetPageByUrl]    Script Date: 10/23/2010 10:05:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetPageByUrl] 
	-- Add the parameters for the stored procedure here
	@siteId int,
	@url nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select *
	from Pages
	where siteId = @siteId and url = @url
END
