 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[UpdatePostStatus]    Script Date: 10/23/2010 10:20:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdatePostStatus]
	-- Add the parameters for the stored procedure here
	@postId int,
	@status tinyint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update Posts
	set [status] = @status
	where postId = @postId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
