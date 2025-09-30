 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[ToggleEnableLanguage]    Script Date: 10/23/2010 10:17:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[ToggleEnableLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int,
	@enable bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update Languages
	set [enable] = ~[enable]
	where languageId = @languageId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
