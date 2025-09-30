ALTER function [dbo].[Aff_CountMember] (  
@AffID int)  
RETURNS int  
AS  
/*  
 Task : Count number of members for Affiliate  
 Author : Peter@20090909  
   
*/  
BEGIN   
   Declare @count int  
   
 select @count=Sum(1)  
   from MemberInfo with (nolock)    
   where AffID=@AffID and IsRemoved = 0     
  return @count  
END  