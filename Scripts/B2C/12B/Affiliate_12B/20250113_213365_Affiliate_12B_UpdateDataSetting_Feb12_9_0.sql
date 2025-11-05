/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250113@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Update data setting [RedmineID: #212201]

*/

USE Affiliate_12B
GO

UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
SET SValue = '2025-01-31'
WHERE SName = 'AFF_CommissionDate'
GO

UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
SET SValue = '2025-02-01'
WHERE SName = 'LastImportedTime_ExchangeOanda'
GO

UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
SET SValue = '2008-03-12 00:00:00' -- Oldest member
WHERE SName IN ('MemberInfoLastImportedTime', 'MemberInfoLastUpdatedTime')
GO