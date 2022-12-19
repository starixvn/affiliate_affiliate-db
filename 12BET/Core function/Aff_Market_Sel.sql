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
*/
BEGIN
	SET NOCOUNT ON
	
	SET @UserId = ISNULL(@UserId, 0)
	
	IF @UserId <> 0
	BEGIN
		SELECT m.MarketId, m.MarketName, m.MarketNativeName, m.ShortedCode, m.DisplayName
		FROM dbo.Users u WITH (NOLOCK)
			INNER JOIN dbo.UserMarket um WITH (NOLOCK) ON um.CustId = u.CustId
			INNER JOIN dbo.Market 	   m WITH (NOLOCK) ON m.MarketId = um.MarketId
		WHERE u.CustId = @UserId
	END
	ELSE
	BEGIN
		SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName
		FROM dbo.Market WITH (NOLOCK)
	END
END
GO