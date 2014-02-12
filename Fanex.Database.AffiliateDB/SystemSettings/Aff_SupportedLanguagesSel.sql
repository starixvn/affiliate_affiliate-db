   set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

-- =============================================
-- Author:		Smith
-- Create date: 2011/02/23
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[Aff_SupportedLanguagesSel]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select SID,SName as [Key],SValue as [TypeName] from SystemSettings (nolock) where [Type]='SupportedLanguages' order by [SValue]
END

GO
GRANT EXECUTE ON [dbo].[Aff_SupportedLanguagesSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_SupportedLanguagesSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SupportedLanguagesSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SupportedLanguagesSel] TO [vnteam]