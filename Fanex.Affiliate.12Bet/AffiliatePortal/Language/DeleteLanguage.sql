 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[DeleteLanguage]    Script Date: 10/22/2010 10:25:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DeleteLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @code nvarchar(50)
	declare @result bit
    -- Insert statements for procedure here
    
    set @code = (select code from Languages where languageId = @languageId)
    
	delete from Languages
	where languageId = @languageId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
	
	--delete related data
	delete from EmbeddableLanguages
    where languageCode = @code
    
    delete from TermLanguages
    where languageCode = @code
    
    delete from ThemeLanguages
    where languageCode = @code
	
	select @result
END
