/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/

/*
	Created: 20230929@Eddie
	DB: DBAFF-Affiliate_Athena000, DBAFF-Affiliate_Aoncash, DBAFF-Affiliate_ItcBet, DBAFF-Affiliate_MacauBet, DBAFF-Affiliate_Spondemo, DBAFF-Affiliate_9Bet
	Task: Change datatype of column "IP" of table "UserLog" and create new table [RedmineID : #194605]
*/
-- old datatype: IP with VARCHAR(20)
ALTER TABLE dbo.UserLog
ALTER COLUMN IP VARCHAR(50) NULL
GO

CREATE TABLE [dbo].[UserLogIsRollbacked](
	RefNo 		INT NULL
	,TypeID 	INT NULL
	,Typename 	VARCHAR(50) NULL
	,Creator 	INT NULL
	,AffID 		INT NULL
	,LoggedDate DATETIME NULL
	,SPName 	VARCHAR(50) NULL
	,IP 		VARCHAR(50) NULL
	,Details 	NVARCHAR(4000) NULL
	,ErrorMsg 	NVARCHAR(4000) NULL
) ON [UserLogData]
GO