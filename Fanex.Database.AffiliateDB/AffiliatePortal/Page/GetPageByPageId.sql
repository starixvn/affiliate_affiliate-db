 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetPageByPageId]    Script Date: 10/23/2010 10:03:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/07/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetPageByPageId] 
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select *
	from Pages
	where pageId = @pageId
END
