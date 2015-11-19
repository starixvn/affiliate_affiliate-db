ALTER PROCEDURE [dbo].[AffAdmin_AffiliateSelGeneralInfo]
	@LicenseeID		INT 
	,@Username		NVARCHAR(30)
	,@UserId		INT				= 0
	,@Currencies	VARCHAR(100)	= NULL
	,@IsITAdmin		BIT				= 0
AS
/*  
 Created: 20090730@Peter  
 Task : Select affiliate info for left panel  
 DB: DB052.Affiliate_ZZun  
  
 Revisions:  
	- 20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_ZZun  
                     Remove the theory of pending commission and CurrCommEarning     
                     Get PreferredPayment to check approve   
	- 20140819@Bobby: Apply SQL style scope
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	
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

	DECLARE @tmpCurrency TABLE (
		CurrencyID INT
		,ExRate FLOAT
		)

	SELECT CAST(val AS INT) AS CurrencyID
	INTO #TblCurrency
	FROM [dbo].[strSplit](@Currencies, ',')

	IF (
			@Currencies IS NULL
			OR @Currencies LIKE ''
			) -- All Currency selected
	BEGIN
		INSERT INTO @tmpCurrency
		SELECT AffCurrencyID
			,0 AS ExRate
		FROM dbo.AffAdmin_f_UserCurrency_Select(@userID, @LicenseeID, '')
	END
	ELSE
	BEGIN
		INSERT INTO @tmpCurrency
		SELECT AffCurrencyID
			,0 AS ExRate
		FROM dbo.AffAdmin_f_UserCurrency_Select(@userID, @LicenseeID, '') r
			INNER JOIN #TblCurrency s ON s.CurrencyID = r.AffCurrencyID
	END

	DROP TABLE #TblCurrency

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
			@Currencies IS NULL
			OR a.Currency IN (
				SELECT CurrencyID
				FROM @tmpCurrency
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

GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelGeneralInfo] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateSelGeneralInfo] TO [vnteam]
