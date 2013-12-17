 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[InsertLanguage]    Script Date: 10/23/2010 10:11:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertLanguage]
	-- Add the parameters for the stored procedure here
	@code nvarchar(50),
	@name nvarchar(64),
	@enable bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into Languages(code, name, enable)
	values(@code, @name, @enable)
	if @@error <>0
		select 0
	else
		select cast(scope_identity() as int)
END
