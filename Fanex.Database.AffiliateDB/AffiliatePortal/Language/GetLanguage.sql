 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[GetLanguage]    Script Date: 10/23/2010 10:01:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/06/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select *
	from Languages
	where languageId = @languageId
END
