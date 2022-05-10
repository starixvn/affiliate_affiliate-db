/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20220511@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Create new tables
*/
CREATE TABLE dbo.bettrans_N2
(
	dealId 			BIGINT
	,startdate 		DATETIME
	,enddate 		DATETIME
	,status 		TINYINT
	,code 			VARCHAR(100)
	,login 			VARCHAR(50)
	,valid_turnover MONEY
	,hold 			MONEY
	,betid 			BIGINT
	,IBCCustId 		INT
	,WinlostDate 	SMALLDATETIME
	,CONSTRAINT [PK_bettrans_N2] PRIMARY KEY NONCLUSTERED 
	(
		betid ASC
	)
) ON [ReportData]


CREATE TABLE dbo.bettrans_EA
(
	dealId 			BIGINT
	,startdate 		DATETIME
	,enddate		DATETIME
	,status 		TINYINT
	,code 			VARCHAR(100)
	,login 			VARCHAR(50)
	,valid_turnover MONEY
	,hold 			MONEY
	,betid 			BIGINT
	,IBCCustId 		INT
	,WinlostDate 	SMALLDATETIME
	,CONSTRAINT [PK_bettrans_EA] PRIMARY KEY NONCLUSTERED 
	(
		betid ASC
	)
)  ON [ReportData]