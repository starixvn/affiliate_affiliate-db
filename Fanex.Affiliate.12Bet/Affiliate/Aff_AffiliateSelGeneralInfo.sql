
ALTER PROCEDURE [dbo].[Aff_AffiliateSelGeneralInfo]
	@Username nvarchar(30),
	@IsCasino bit = 0 OUTPUT
AS
/*
	Created: 20090730@Peter
	Task : Select affiliate info for left panel
	DB: DB052.Affiliate_12BET

	Revisions:
	  .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_12BET
						Remove the theory of pending commission and CurrCommEarning   
						Get PreferredPayment to check approve 
	  .20090823@Peter : Move table on_user to Affiliate_12Bet DB  
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


	
SELECT 	--Get affiliate info
	IsClosed as closed,
	IsLocked, 	
	a.Username,	
	Username2,	
	a.AffID,
	firstname,
	lastname,
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
	left join CommGroup c (nolock)  on c.groupid=a.groupid
WHERE a.AffID=@AffID 	

--EXEC DB03.On_User.dbo.Acc_CustomerSelOnline @Custid = @AffID --Current Online List

SELECT * FROM on_user (nolock)
WHERE custid = @AffID
ORDER BY on_userid

if(Exists(Select top 1 CValue 
			From CommonSettings (nolock)  					
			Where [Type]='12betcasino' and CName = @Username))
	select @IsCasino = 1

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelGeneralInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelGeneralInfo] TO [VNTeam]
