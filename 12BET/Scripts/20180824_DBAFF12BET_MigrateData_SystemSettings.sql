USE [Affiliate_12BET]
GO

/*
	Created: 20180827@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Migrate data to new tables - Common Setting
*/

-- I. CutOffDate (1 row)
	UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
	SET SValue = '2018-09-30'
	WHERE SName = 'AFF_CutOffReportDate'

-- II. Commission Date (1 row)
	UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
	SET SValue = '2018-08-31'
	WHERE SName = 'AFF_CommissionDate'

-- III. Remove Betlist (2 rows)
	DELETE dbo.CommonSettings WITH (ROWLOCK, UPDLOCK)
	WHERE Type = 'PlayerDetail'