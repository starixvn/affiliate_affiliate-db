 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[UpdatePost]    Script Date: 10/23/2010 10:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdatePost]
	-- Add the parameters for the stored procedure here
	@postId int,
	@title nvarchar(256),
	@description varchar(1024),
	@content varchar(MAX),
	@type tinyint,
	@status tinyint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update	Posts
	set		title =@title, 
			[description] = @description, 
			content = @content, 
			[type] = @type, 
			[status] = @status,
			updatedDate = getdate()
			
	where	postId = @postId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
