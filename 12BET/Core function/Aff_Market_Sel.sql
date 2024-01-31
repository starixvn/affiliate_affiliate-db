/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Market_Sel]
	@UserId	INT = 0
AS
/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core SP - Get market (PreferredLanguage)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200303@Percy: Return more columns [RedmineID: #121973]
		- 20221110@Eddie: Support Block Market [RedmineID: #179537]
		- 20230330@Eddie: Change order of Bangladesh Language [RedmineID: #186108]
		- 20240124@Eddie: reorder market [RedmineID: #200168]
	Note: Order of English always is 1st
*/
BEGIN
	SET NOCOUNT ON
	
	SET @UserId = ISNULL(@UserId, 0)
	
	IF @UserId <> 0
	BEGIN
		;WITH CTE_Language AS(
			SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName,
				   CASE MarketId WHEN 'en-US' THEN 1
								 WHEN 'bn-BD' THEN 2
								 WHEN 'en-GB' THEN 3
								 WHEN 'hi-IN' THEN 4
								 WHEN 'hi'    THEN 5
								 WHEN 'te-IN' THEN 6
				   ELSE 7 END AS TypeId
			FROM dbo.Market WITH (NOLOCK)
		)
		SELECT m.MarketId, m.MarketName, m.MarketNativeName, m.ShortedCode, m.DisplayName
		FROM dbo.Users u WITH (NOLOCK)
			INNER JOIN dbo.UserMarket um WITH (NOLOCK) ON um.CustId = u.CustId
			INNER JOIN CTE_Language   m WITH (NOLOCK) ON m.MarketId = um.MarketId
		WHERE u.CustId = @UserId
		ORDER BY m.TypeId, m.MarketId ASC
	END
	ELSE
	BEGIN
		;WITH CTE_Language AS(
			SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName,
				   CASE MarketId WHEN 'en-US' THEN 1
								 WHEN 'bn-BD' THEN 2
								 WHEN 'en-GB' THEN 3
								 WHEN 'hi-IN' THEN 4
								 WHEN 'hi'    THEN 5
								 WHEN 'te-IN' THEN 6
				   ELSE 7 END AS TypeId
			FROM dbo.Market WITH (NOLOCK)
		)
		SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName
		FROM CTE_Language
		ORDER BY TypeId, MarketId ASC
	END
END
GO