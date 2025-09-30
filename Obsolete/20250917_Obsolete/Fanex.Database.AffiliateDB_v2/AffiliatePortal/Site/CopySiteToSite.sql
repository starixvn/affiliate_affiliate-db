 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[CopySiteToSite]    Script Date: 10/22/2010 10:25:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[CopySiteToSite]
	-- Add the parameters for the stored procedure here
	@fromSiteId int,
	@toSiteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- copy here
    --1. Sites table (only bodyLayoutId, footerLayoutId, other fields were filled)
    --2. Sites Meta table
    --3. Pages table (after copy this table, update homePageId of Sites table)
    --4. PageEmbeddables table
    --5. PageEmbeddableMeta table
    --6. Menu table
    
    -- return
	select cast(1 as bit)
END
