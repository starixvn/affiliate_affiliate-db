CREATE Function [dbo].[Aff_IPConvertToNumber] (  
 @IP varchar(22)  
)  
RETURNS bigint  
AS  
/*  
    DB : DB05.Affiliate_ZZun  
 Task : Convert IP format to integer number  
 Author : Peter@20100127  
   
*/  
BEGIN      
 SET @IP=ltrim(rtrim(@IP))  
 If(@Ip LIKE '%_%.%_%.%_%.%_%')  
 Begin  
  Declare @IpA bigint, @IpB int, @IpC int, @IpD int, @IpI bigint  
    
  Select @IpA = Left(@Ip, PATIndex('%.%', @IP) - 1)   
  Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpA) - 1)  
    
  Select @IpB = Left(@Ip, PATIndex('%.%', @IP) - 1)   
  Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpB) - 1)  
    
  Select @IpC = Left(@Ip, PATIndex('%.%', @IP) - 1)   
  Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpC) - 1)  
    
  Select @IpD = @Ip  
    
  Return (@IpA * 256*256*256) + (@IpB * 256 * 256) + (@IpC * 256) + @IpD   
 End  
 Return 0  
END  