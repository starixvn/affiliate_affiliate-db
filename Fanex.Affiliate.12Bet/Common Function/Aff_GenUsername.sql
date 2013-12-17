ALTER Procedure [Aff_GenUsername]
	@AffPrefix varchar(20) = '12BetAff',
	@username varchar(50) OUTPUT = ''
AS
/*    
Created:   
Task : Generate username with the prefix for new Aff
DB: DB052.Affiliate_12BET
Original: [Aff_AffiliateIns]  
Revisions:    

Param's Explanation:    
	@AffPrefix: 12BetAff or 12BetMedia
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
  
select @username = isnull(SUBSTRING(@username, @LenPrefix + 1, len(@username) - @LenPrefix), '0')
  
select @username = convert(varchar(20), convert(int, @username) + 1)  
  
if len(@username)<3  
BEGIN  
	select @Username = right('00' + @username, 3)  
END  
	select @username = @AffPrefix + @username  
	
GO
GRANT EXECUTE ON [dbo].[Aff_GenUsername] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GenUsername] TO [vnteam]

