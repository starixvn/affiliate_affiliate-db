/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Market_Sel]
	@CustId	INT = NULL
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - View user market's permission

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
		- 20230330@Eddie: Change order of Bangladesh Language [RedmineID: #186108]
		- 20240820@Eddie: Hide Hindi Market [RedmineID: #209409]
	Note: Order of English always is 1st
*/

BEGIN
	SET NOCOUNT ON

	-- Policy: 0: Not allow, 1: Read, 3: Host
	IF @CustId IS NULL
	BEGIN
		;WITH CTE_Language AS(
			SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName,
				   CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS TypeId
			FROM dbo.Market WITH (NOLOCK)
			WHERE MarketId <> 'hi'
		)
		SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName, 1 AS Status
		FROM CTE_Language
		ORDER BY TypeId, MarketId ASC
	END
	ELSE
	BEGIN
		;WITH CTE_Language AS(
			SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName,
				   CASE WHEN MarketId = 'en-US' THEN 1 ELSE 2 END AS TypeId
			FROM dbo.Market WITH (NOLOCK)
			WHERE MarketId <> 'hi'
		)
		SELECT m.MarketId, m.MarketName, m.DisplayName, m.MarketNativeName, m.ShortedCode
			,CASE WHEN um.MarketId IS NULL THEN 0 ELSE 1 END AS Status
		FROM CTE_Language m
			LEFT JOIN dbo.UserMarket um WITH (NOLOCK) ON um.MarketId = m.MarketId AND um.CustId = @CustId
		ORDER BY m.TypeId, m.MarketId ASC
	END
END
GO