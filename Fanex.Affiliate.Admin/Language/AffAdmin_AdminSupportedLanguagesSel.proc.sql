CREATE Procedure [dbo].[AffAdmin_AdminSupportedLanguagesSel]  
    
AS  
/*Created: 20130812@Johnny
Task : Admin Language list
DB: Alpha

Revisions:
	- 20130812@Johnny : Create
Param's Explanation:
*/    
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
GRANT EXECUTE ON [dbo].[AffAdmin_AdminSupportedLanguagesSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AdminSupportedLanguagesSel] TO [vnteam]