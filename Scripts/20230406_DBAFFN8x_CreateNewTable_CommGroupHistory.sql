/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20230406@Malcolm 
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Add new table :  CommGroupHistory [RedminId : # 185481]
*/

/*
USE Affiliate_N88
GO

USE Affiliate_N8B
GO

USE Affiliate_N8G
GO
*/

CREATE TABLE dbo.CommGroupHistory
(
	MonthDate DATETIME
	,GroupId INT
	,SubCommRate DECIMAL(9, 8)
	, CONSTRAINT [PK_CommGroupHistory] PRIMARY KEY CLUSTERED 
	(
		MonthDate ASC, GroupId
	)
) ON [SettingData]
GO

ALTER TABLE dbo.CommGroup
ADD SubCommRate DECIMAL(9, 8)
GO




