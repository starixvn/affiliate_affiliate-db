/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Market_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Core SP - Get market (PreferredLanguage)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	SELECT MarketId, MarketName
	FROM dbo.Market WITH (NOLOCK)
END
GO