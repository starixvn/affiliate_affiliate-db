/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230413@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update 'TransactionId' to lowercase [RedmineId : #180311]
*/
UPDATE b
SET b.TransactionId = LOWER(b.TransactionId)
FROM dbo.bettrans_APIProductsTest b WITH (ROWLOCK, UPDLOCK)
GO

ALTER TABLE dbo.bettrans_APIProductsTest DROP CONSTRAINT [PK_bettrans_APIProductsTest]
GO

ALTER TABLE dbo.bettrans_APIProductsTest
ALTER COLUMN TransactionId VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL
GO

ALTER TABLE dbo.bettrans_APIProductsTest ADD  CONSTRAINT [PK_bettrans_APIProductsTest] PRIMARY KEY NONCLUSTERED 
(
	TpType 			ASC
	,SubItem 		ASC
	,TransactionId 	ASC
)ON [ReportData]
GO