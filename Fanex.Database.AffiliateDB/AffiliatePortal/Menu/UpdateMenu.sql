 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[UpdateMenu]    Script Date: 10/23/2010 10:19:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateMenu]
	-- Add the parameters for the stored procedure here
	@menuId int,
	@parentId int,
	@name nvarchar(256),
	@link nvarchar(256),
	@pageId uniqueidentifier
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	Declare @new_link nvarchar(256)
	if @pageid is not null
		set @new_link = ''
	else 
		set @new_link = @link
    
	update Menu
	set		name = @name,
			pageId = @pageId,
			link = @new_link	
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
