/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200512@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Supported languages - Updated
*/

DELETE dbo.Market WITH (ROWLOCK, UPDLOCK)
WHERE MarketId NOT IN ('en-US', 'id-ID', 'th-TH', 'zh-CN', 'zh-TW')
GO
