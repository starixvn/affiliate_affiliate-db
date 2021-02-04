/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add a new table [RedmineID: #145276]
*/
CREATE TABLE dbo.Newsletter
(
	NewsletterId INT IDENTITY(1, 1) NOT NULL
	,FileName NVARCHAR(200)
	,FileSize INT
	,Language VARCHAR(50)
	,CreatedAt DATETIME DEFAULT(GETDATE())
	,EffectiveFromDate DATETIME
	,EffectiveToDate DATETIME
	,CONSTRAINT PK_Newsletter PRIMARY KEY CLUSTERED (NewsletterId)
) ON [DATA]

