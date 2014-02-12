ALTER PROCEDURE [dbo].[Aff_AffiliateSelGeneralInfo]  
 @Username nvarchar(30)   
AS  
/*  
 Created: 20090730@Peter  
 Task : Select affiliate info for left panel  
 DB: DB052.Affiliate_ZZun  
  
 Revisions:  
   .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_ZZun  
                     Remove the theory of pending commission and CurrCommEarning     
                     Get PreferredPayment to check approve   
 Param's Explanation:  
 • @Username : Affiliate username  
*/  
SET NOCOUNT ON  
Declare @affID int  
Select @affID = affID from AffInfo with(nolock) where username = @Username  
  
if @affID is null  
Begin  
 Select @affID = affID from AffInfo with(nolock) where username2 = @Username  
 if @affID is null return  
End  
  
  
   
SELECT  --Get affiliate info  
 IsClosed as closed,  
 IsLocked,    
 a.Username,    
 a.AffID,  
 firstname,  
 lastname,  
 e.Prefix,  
 gender,  
 email,  
 phone,  
 mobilephone,  
 siteurl,  
 lastLoginDate,  
 lastLoginIP as lastloginip,   
 PreferredLanguage,  
 PreferredPayment,  
 Player_Username,  
 status,  
 MailOption,--Johnny Add to send relevant email format.  
 isnull(c.groupname,'') as groupname,   
    isnull(c.groupid,-1) as groupid,  
 isnull(dbo.Aff_GetAffBalance(@AffId), 0) as BalBroughtForward,  
 AffType  
FROM AffInfo a with(nolock)    
 inner join AffDetail d on a.AffID = d.AffID  
 left join Exchange e with(nolock) on a.Currency = e.ExchangeID  
 left join CommGroup c (nolock)  on c.groupid=a.groupid  
WHERE a.AffID=@AffID    
  
SELECT * FROM on_user (nolock)  
WHERE custid = @AffID  
ORDER BY on_userid  

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelGeneralInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelGeneralInfo] TO [VNTeam]
