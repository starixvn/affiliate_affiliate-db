/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Market_Sel]
	@CustId	INT = NULL
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - View user market's permission

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	-- Policy: 0: Not allow, 1: Read, 3: Host
	IF @CustId IS NULL
		SELECT m.MarketId, m.MarketName, m.DisplayName, m.MarketNativeName, m.ShortedCode
			,1 AS Status
		FROM dbo.Market m WITH (NOLOCK)
	ELSE
		SELECT m.MarketId, m.MarketName, m.DisplayName, m.MarketNativeName, m.ShortedCode
			,CASE WHEN um.MarketId IS NULL THEN 0 ELSE 1 END AS Status
		FROM dbo.Market m WITH (NOLOCK)
			LEFT JOIN dbo.UserMarket um WITH (NOLOCK) ON um.MarketId = m.MarketId AND um.CustId = @CustId
END
GO