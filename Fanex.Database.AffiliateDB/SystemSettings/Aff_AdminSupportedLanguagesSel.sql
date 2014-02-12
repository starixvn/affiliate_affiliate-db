
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 30-05-2013
-- Description:	Get Admin Supported Languages Information
-- =============================================
ALTER Procedure [dbo].[Aff_AdminSupportedLanguagesSel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @Languages varchar(max)
    select @Languages=(select SValue from SystemSettings where SName = 'AFF_AdminSupportedLanguages' and Type ='Meta')
	-- Insert statements for procedure here
	select LanguageID , LanguageName from Language (nolock)
	where LanguageID in (select val from [dbo].[strSplit] ( @Languages, ',' ) )
	Order by [Order]



END

GO
GRANT EXECUTE ON [dbo].[Aff_AdminSupportedLanguagesSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminSupportedLanguagesSel] TO [vnteam]
  