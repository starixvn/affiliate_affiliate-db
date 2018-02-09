/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateSelGeneralInfo]
	@Username		NVARCHAR(30),
	@UserCurrencies	VARCHAR(MAX)	= '',
	@IsITAdmin		BIT				= 0
AS

/*  
	Created: 20090730@Peter  
	Task: Select affiliate info for left panel  
	DB: DBAFF.Affiliate_Athena000  
  
	Revisions:  
		- 20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_ZZun  
							Remove the theory of pending commission and CurrCommEarning     
							Get PreferredPayment to check approve   
		- 20140819@Bobby: Apply SQL style scope
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180205@Percy: Replace @UserId, @LicenseeId to @UserCurrencies to get of currencies [RedmineID: #90545]
	
	Param's Explanation:  
		• @Username : Affiliate username  
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @affID INT

	SELECT @affID = affID
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE username = @Username

	IF @affID IS NULL
	BEGIN
		SELECT @affID = affID
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE username2 = @Username

		IF @affID IS NULL RETURN
	END

	SELECT --Get affiliate info  
		IsClosed AS closed
		,IsLocked
		,a.Username
		,a.AffID
		,firstname
		,lastname
		,e.Prefix
		,gender
		,email
		,phone
		,mobilephone
		,siteurl
		,lastLoginDate
		,lastLoginIP AS lastloginip
		,PreferredLanguage
		,PreferredPayment
		,Player_Username
		,STATUS
		,MailOption
		,--Johnny Add to send relevant email format.  
		isnull(c.groupname, '') AS groupname
		,isnull(c.groupid, - 1) AS groupid
		,a.BF AS BalBroughtForward
		,AffType
		,e.Code AS CurrencyCode
		,a.Currency
		,a.TestLevel
	FROM dbo.AffInfo a WITH (NOLOCK)
		INNER JOIN dbo.AffDetail d ON a.AffID = d.AffID
		LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON a.Currency = e.ExchangeID
		LEFT JOIN dbo.CommGroup c(NOLOCK) ON c.groupid = a.groupid
	WHERE a.AffID = @AffID
		AND (
			@UserCurrencies IS NULL
			OR a.Currency IN (
				SELECT CAST(val AS INT)
				FROM [dbo].[strSplit](@UserCurrencies, ',')
				)
			)
		AND (
			@IsITAdmin = 1
			OR (
				@IsITAdmin = 0
				AND a.TestLevel IN (0, 1)
				)
			)

	SELECT *
	FROM dbo.on_user(NOLOCK)
	WHERE custid = @AffID
	ORDER BY on_userid
END
GO