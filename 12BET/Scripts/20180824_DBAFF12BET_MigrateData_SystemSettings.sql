USE [Affiliate_12BET]
GO

/*
	Created: 20180827@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Migrate data to new tables - Common Setting
*/

-- I. CutOffDate
	UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
	SET SValue = '2018-09-01'
	WHERE SName = 'AFF_CutOffReportDate'

-- II. Commission Date
	UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
	SET SValue = '2018-08-31'
	WHERE SName = 'AFF_CommissionDate'