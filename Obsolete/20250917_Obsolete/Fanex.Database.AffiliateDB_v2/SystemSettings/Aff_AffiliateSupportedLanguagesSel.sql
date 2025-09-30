
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter
-- Create date: 30-05-2013
-- Description:	Get Affiliate Supported Languages Information
-- Revision:
	-- 20130813@Joseph: add Environment param
-- =============================================
ALTER Procedure [dbo].[Aff_AffiliateSupportedLanguagesSel]
 @Environment varchar(50) = 'Production' 
AS
BEGIN
 
 SET NOCOUNT ON;

    declare @Languages varchar(max)
    select @Languages=(select top(1) SValue from SystemSettings where SName = 'AFF_AffiliateSupportedLanguages' and Type ='Meta' and 
    ((@Environment = 'Production' and coalesce(Environment,'')='') or Environment = @Environment))
 -- Insert statements for procedure here
 select LanguageID , LanguageName from Language (nolock)
 where LanguageID in (select val from [dbo].[strSplit] ( @Languages, ',' ) ) 
 Order by [Order]



END


GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSupportedLanguagesSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSupportedLanguagesSel] TO [vnteam]
  