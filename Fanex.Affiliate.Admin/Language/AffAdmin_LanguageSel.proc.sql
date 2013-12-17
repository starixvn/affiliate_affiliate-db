CREATE Procedure [dbo].[AffAdmin_LanguageSel]  
   
AS  
-- DB052.Affiliate_12Bet  
   
  
SELECT *   
FROM Language  
Order by [Order]  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_LanguageSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_LanguageSel] TO [vnteam]