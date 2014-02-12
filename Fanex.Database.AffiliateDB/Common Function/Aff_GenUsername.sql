ALTER Procedure [dbo].[Aff_GenUsername]  
 @AffPrefix varchar(20) = 'AFF',  
 @username varchar(50) = '' OUTPUT  
AS  
/*      
Created:     
Task : Generate username with the prefix for new Aff  
DB: DB052.Affiliate_ZZun  
Original: [Aff_AffiliateIns]    
Revisions:      
  
Param's Explanation:      
 @AffPrefix: Aff or Media  
 @username: Return the @AffPrefix + sequence number of prefix  
*/  
declare @LenMax int, @LenPrefix int  
  
select @LenPrefix = len(@AffPrefix)    
  
select @LenMax = max(len(username))    
from AffInfo with (nolock)    
where username like @AffPrefix + '%'  
    
Select @username=max(username)    
from AffInfo with (nolock)  
where len(username)= @LenMax  
 and username like @AffPrefix + '%'  
   
if(@LenMax is null or @username is null)  
BEGIN  
 set @username = @AffPrefix + '1001'    
 return  
END    
  
    
select @username = isnull(SUBSTRING(@username, @LenPrefix + 1, len(@username) - @LenPrefix), '0')   
select @username = convert(varchar(20), convert(int, @username) + 1)    
  
if len(@username)<5    
BEGIN    
 select @Username = right('100' + @username, 4)    
END    
 select @username = @AffPrefix + @username  
GO
GRANT EXECUTE ON [dbo].[Aff_GenUsername] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GenUsername] TO [vnteam]

