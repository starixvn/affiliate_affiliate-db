/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

CREATE PROCEDURE [dbo].[Aff_Market_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core SP - Get market (PreferredLanguage)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200303@Percy: Return more columns [RedmineID: #121973]
*/

BEGIN
	SET NOCOUNT ON

	SELECT MarketId, MarketName, MarketNativeName, DisplayName, ShortedCode
	FROM dbo.Market WITH (NOLOCK)
END
GO