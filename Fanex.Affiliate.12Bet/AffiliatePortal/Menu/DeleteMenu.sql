 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[DeleteMenu]    Script Date: 10/22/2010 10:25:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DeleteMenu]
	-- Add the parameters for the stored procedure here
	@menuId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	delete from Menu
	where menuId = @menuId
	
	select cast(@@rowcount as bit)
END
