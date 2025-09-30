ALTER Procedure [dbo].[AffAdmin_AffiliateSupportedLanguagesSel]  
    
AS  
BEGIN  
   
SET NOCOUNT ON;  
  
declare @Languages varchar(max)  
select @Languages=(select SValue from SystemSettings where SName = 'AFF_AffiliateSupportedLanguages' and Type ='Meta')  

-- Insert statements for procedure here  
select LanguageID , LanguageName from Language (nolock)  
where LanguageID in (select val from [dbo].[strSplit] ( @Languages, ',' ) )  
Order by [Order]  
  
  
  
END  
  

