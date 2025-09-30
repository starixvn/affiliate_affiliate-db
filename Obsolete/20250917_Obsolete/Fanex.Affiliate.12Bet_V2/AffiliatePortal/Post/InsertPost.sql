 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[InsertPost]    Script Date: 10/23/2010 10:13:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/07/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertPost]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@title nvarchar(256),
	@description nvarchar(1024),
	@content nvarchar(MAX),
	@type tinyint,
	@status tinyint,
	@parentId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into Posts(siteId,title,[description],content,[type],[status],createdDate,updatedDate,parentId)
    values(@siteId,@title,@description,@content,@type,@status,getdate(),getdate(),@parentId)
    
    IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
