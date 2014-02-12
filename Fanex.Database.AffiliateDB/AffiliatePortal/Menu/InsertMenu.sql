 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[InsertMenu]    Script Date: 10/23/2010 10:11:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/01/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertMenu]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@parentId int,
	@level tinyint,
	@orderNo int,
	@name nvarchar(256),
	@link nvarchar(256),
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--get maxOrderNo
	declare @maxOrderNo int
	set @maxOrderNo = dbo.GetMaxMenuOrderNo(@siteId, @parentId, @level) + 1
	
    -- Insert statements for procedure here
	INSERT INTO		Menu(siteId,parentId, level,orderNo, name, link, pageId)
	VALUES(@siteId,@parentId, @level,@maxOrderNo, @name, @link, @pageId)
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
