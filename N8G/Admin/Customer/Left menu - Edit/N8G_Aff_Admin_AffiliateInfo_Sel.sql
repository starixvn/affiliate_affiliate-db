/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateInfo_Sel]
	@AffId		INT = NULL,
	@Username	NVARCHAR(50) = NULL
AS

/*
	Creator: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task:
		Admin site - Customer - Edit (view)
		Admin site - Customer - Left menu (view)
	
	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
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

	SELECT
		p.AffId AS ParentAffId,
		p.UserName AS ParentAffName,
		ai.AffId,
		ai.AffType,
		ai.Status,
		ai.IsClosed AS Closed,
		ai.IsLocked,
		ad.LastLoginDate,
		ad.LastLoginIP,
		-- Personal Information
		ai.UserName,
		ai.UserName2,
		ai.FirstName,
		ai.LastName,
		ISNULL(ad.Gender, 0) AS Gender,
		ai.Email,
		ad.Phone,
		ad.ContactApps,
		-- Additional Information
		ad.Address,
		ad.City,
		ad.State,
		ad.Postal,
		ad.Country,
		ISNULL(q.Question, ad.Question) AS Question,
		ad.Answer,
		-- Email Format Preference
		ad.MailOption,
		-- Website Information
		ad.SiteURL ,
		ad.MoreSiteURLs,
		ad.NoSiteDesc,
		-- Commission Group Information
		ISNULL(cg.GroupId, 0) AS GroupId,
		ISNULL(cg.GroupName, '') AS GroupName,
		ISNULL(cg.IsPrivate, 0) AS IsPrivate,
		ISNULL(b.BalBroughtForward, 0) AS BalBroughtForward,
		-- Language
		ad.PreferredLanguage,
		-- Payment Information
		ad.PreferredPayment, -- Player, Neteller, Moneybookers, Wire (Bank Transfer)
			-- Player
		ad.Player_Username		AS PlayerUsername,
			-- Netteller
		ad.Neteller_AccountID	AS NetellerAccountId,
			-- Moneybookers
		ad.Moneybookers_Email	AS MoneybookersEmail,
			-- Wire (Bank Transfer)
		ad.Wire_BankName	AS BankName,
		ad.Wire_BankAddress AS BankAddress,
		ad.Wire_SwiftCode	AS BankSwiftCode,
		ad.Wire_AccountName AS BankAccountName,
		ad.Wire_AccountNo	AS BankAccountNo,
		-- More info
		ISNULL(u.UserName, '') AS ApprovedBy,
		ISNULL(dep.IsDeductedPercent, 0) AS Dep_IsDeductedPercent,
		ISNULL(wit.IsDeductedPercent, 0) AS Wit_IsDeductedPercent
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		LEFT JOIN dbo.AffInfo p WITH (NOLOCK) ON ai.ParentAffId = p.AffId
		OUTER APPLY dbo.Aff_f_GetBalBroughtForward (@AffId) b
		LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
		OUTER APPLY (SELECT TOP 1 ds.IsDeductedPercent FROM dbo.DeductionSetting ds WITH (NOLOCK) WHERE cg.GroupId = ds.GroupId AND ds.DeductionId = 13) dep
		OUTER APPLY (SELECT TOP 1 ds.IsDeductedPercent FROM dbo.DeductionSetting ds WITH (NOLOCK) WHERE cg.GroupId = ds.GroupId AND ds.DeductionId = 14) wit
		LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON ai.ApprovedBy = u.CustId
		LEFT JOIN dbo.Aff_f_Get_SecurityQuestions ('en-US') q ON ad.QuestionID = q.QuestionID
	WHERE ai.AffId = @AffId
END
GO
