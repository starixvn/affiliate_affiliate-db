ALTER PROCEDURE [dbo].[Aff_MemberSel]  
 @username varchar(30)  
AS  
/*  
 Created: 20090701@Jacob   
 DB: DB052.Affiliate_ZZun  
  
*/  
SET NOCOUNT ON;  
SELECT UserName  
   ,[IBCCustID]  
      ,[AffID]  
      ,[UserName]  
      ,[IBCUserName]  
      ,[CreatedDate]  
      ,[RegisteredDate]  
      ,[IsRemoved]  
      ,[DepositCustID]  
      ,[FirstName]  
      ,[LastName]  
      ,[Currency]  
      ,[Email]  
      ,[Recommend]  
FROM [MemberInfo]  
WHERE [username]= @UserName  

GO
GRANT EXECUTE ON [dbo].[Aff_MemberSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberSel] TO [vnteam]
  

