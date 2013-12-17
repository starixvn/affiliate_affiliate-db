ALTER PROCEDURE [dbo].[AffAdmin_AffiliateSelGeneralInfo]  
	@Username nvarchar(30),
	@UserId int=0,
	@Currencies varchar(100) = NULL,
	@IsITAdmin bit = 0
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

DECLARE @tmpCurrency TABLE (CurrencyID INT, ExRate FLOAT)

SELECT CAST(val AS INT) AS CurrencyID 
INTO #TblCurrency 
FROM [dbo].[strSplit] ( @Currencies, ',' )

IF (@Currencies IS NULL OR @Currencies LIKE '') -- All Currency selected
BEGIN
	INSERT INTO @tmpCurrency
	SELECT AttributeID, 0 AS ExRate 
	FROM dbo.Aff_f_GetCurrencybyUser (@userID,1)
END
ELSE
BEGIN
	INSERT INTO @tmpCurrency
	SELECT AttributeID, 0 AS ExRate
	FROM dbo.Aff_f_GetCurrencybyUser (@userID,1) r
		INNER JOIN #TblCurrency s ON s.CurrencyID = r.AttributeID
END

DROP TABLE #TblCurrency
  
   
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
	a.BF as BalBroughtForward,  
	AffType, 
	e.Code as CurrencyCode, 
	a.Currency,
	a.TestLevel
FROM AffInfo a with(nolock)    
	inner join AffDetail d on a.AffID = d.AffID  
	left join Exchange e with(nolock) on a.Currency = e.ExchangeID  
	left join CommGroup c (nolock)  on c.groupid=a.groupid  
WHERE a.AffID=@AffID    
	AND (@Currencies IS NULL OR a.Currency IN (SELECT CurrencyID FROM @tmpCurrency))
	AND (@IsITAdmin = 1 OR (@IsITAdmin = 0 AND a.TestLevel IN (0,1)))
  
SELECT * FROM on_user (nolock)  
WHERE custid = @AffID  
ORDER BY on_userid  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelGeneralInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateSelGeneralInfo] TO [vnteam]