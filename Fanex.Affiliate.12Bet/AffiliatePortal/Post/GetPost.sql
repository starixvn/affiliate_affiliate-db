 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[GetPost]    Script Date: 10/23/2010 10:05:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/09/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetPost]
	-- Add the parameters for the stored procedure here
	@postId int,
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    declare @numberCom int
    select @numberCom = count(1) 
    from comments with(nolock)
    where postid = @postId
    
	select *,@numberCom as commentNumber
	from Posts
	where postId = @postId and siteId = @siteId
END
