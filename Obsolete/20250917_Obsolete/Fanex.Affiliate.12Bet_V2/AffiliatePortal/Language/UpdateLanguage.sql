 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[UpdateLanguage]    Script Date: 10/23/2010 10:19:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int,
	@code nvarchar(50),
	@name nvarchar(64)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @oldCode nvarchar(50)
	declare @result bit
    -- Insert statements for procedure here
	set @oldCode = (select code from Languages where languageId = @languageId)
	
	update Languages
	set code = @code, name = @name
	where languageId = @languageId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
		
	--update related data
	if @code <> @oldCode
    begin
		update EmbeddableLanguages
		set languageCode = @code
		where languageCode = @oldCode
	    
		update TermLanguages
		set languageCode = @code
		where languageCode = @oldCode
	    
		update ThemeLanguages
		set languageCode = @code
		where languageCode = @oldCode
    end
	
	
	select @result
	
END
