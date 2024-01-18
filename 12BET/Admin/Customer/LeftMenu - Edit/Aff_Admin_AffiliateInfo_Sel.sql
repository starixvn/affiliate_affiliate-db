/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateInfo_Sel]
	@UserId		INT = 0
	,@AffId		INT = NULL
	,@Username	NVARCHAR(50) = NULL
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task:
		Admin site - Customer - Edit (view)
		Admin site - Customer - Left menu (view)
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190509@Percy: Enhance Security Questions [RedmineID: #104884]
		- 20190614@Percy: Remove IsCasino [RedmineID: #109008]
		- 20200731@Percy: Check permission market (language) by user login [RedmineID: #121975]
		- 20231026@Eddie: Get TargetCountry [RedmineId : #181590]
*/

BEGIN
	SET NOCOUNT ON

	IF @AffId IS NULL
	BEGIN
		-- Search by username
		SELECT @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE UserName = @Username

		-- Search by username2
		IF @AffId IS NULL
			SELECT @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE UserName2 = @Username

		-- Still not found
		IF @AffId IS NULL
			RETURN
	END

	DECLARE @PreferredLanguage VARCHAR(11)
	SELECT  @PreferredLanguage = PreferredLanguage FROM dbo.AffDetail WITH (NOLOCK) WHERE AffId = @AffId

	IF ISNULL(@UserId, 0) <> 0 AND ISNULL(@PreferredLanguage, '') <> ''
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.UserMarket WITH (NOLOCK) WHERE CustId = @UserId AND MarketId = @PreferredLanguage)
			RETURN
	END

	SELECT TOP(1)
		ai.AffId
		,ai.AffType
		,ai.Status
		,ai.IsClosed AS Closed
		,ai.IsLocked
		,ad.LastLoginDate
		,ad.LastLoginIP
		-- Personal Information
		,ai.UserName
		,ai.UserName2
		,ai.FirstName
		,ai.LastName
		,ISNULL(ad.Gender, 0) AS Gender
		,ai.Email
		,ad.Phone
		,ad.ContactApps
		-- Additional Information
		,ad.Address
		,ad.City
		,ad.State
		,ad.Postal
		,ad.Country
		,ad.QuestionId
		,ISNULL(q.Question, ad.Question) AS Question
		,ad.Answer
		-- Email Format Preference
		,ad.MailOption
		-- Website Information
		,ad.SiteURL
		,ad.MoreSiteURLs
		,ad.NoSiteDesc
		-- Commission Group Information
		,ISNULL(cg.GroupId, 0) 			AS GroupId
		,ISNULL(cg.GroupName, '') 		AS GroupName
		,ISNULL(b.BalBroughtForward, 0) AS BalBroughtForward
		-- Target Country
		,ISNULL(tc.CountryName, '') 	AS TargetCountryName
		-- Language
		,ad.PreferredLanguage
		-- Payment Information
		,ad.PreferredPayment -- Player, Neteller, Moneybookers, Wire (Bank Transfer)
			-- Player
		,ad.Player_Username		AS PlayerUsername
			-- Netteller
		,ad.Neteller_AccountID	AS NetellerAccountId
			-- Moneybookers
		,ad.Moneybookers_Email	AS MoneybookersEmail
			-- Wire (Bank Transfer)
		,ad.Wire_BankName		AS BankName
		,ad.Wire_BankAddress 	AS BankAddress
		,ad.Wire_SwiftCode		AS BankSwiftCode
		,ad.Wire_AccountName 	AS BankAccountName
		,ad.Wire_AccountNo		AS BankAccountNo
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		OUTER APPLY dbo.Aff_f_GetBalBroughtForward (@AffId) b
		LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
		LEFT JOIN dbo.Aff_f_Get_SecurityQuestions (1, 'en-US') q ON ad.QuestionID = q.QuestionID
		LEFT JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.CountryCode = ad.TargetCountryCode
	WHERE ai.AffId = @AffId
END
GO