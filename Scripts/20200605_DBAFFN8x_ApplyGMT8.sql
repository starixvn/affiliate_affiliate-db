/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200605@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Apply GMT+8
*/

/*
USE Affiliate_N88
GO

USE Affiliate_N8B
GO

USE Affiliate_N8G
GO
*/

INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('TimeZone', '8')
GO