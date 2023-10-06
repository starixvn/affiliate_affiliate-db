/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230510@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update 'TransactionId' to lowercase [RedmineId : #180311]
*/
-- having 125983 rows
UPDATE b
SET b.TransactionId = LOWER(b.TransactionId)
FROM dbo.bettrans_APIProducts b WITH (ROWLOCK, UPDLOCK)
GO

ALTER TABLE dbo.bettrans_APIProducts DROP CONSTRAINT [PK_bettrans_APIProducts]
GO

ALTER TABLE dbo.bettrans_APIProducts
ALTER COLUMN TransactionId VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL
GO

ALTER TABLE dbo.bettrans_APIProducts ADD  CONSTRAINT [PK_bettrans_APIProducts] PRIMARY KEY NONCLUSTERED 
(
	TpType 			ASC
	,SubItem 		ASC
	,TransactionId 	ASC
)ON [ReportData]
GO