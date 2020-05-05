USE Affiliate_N8B
GO

UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = '2020-04-20'
WHERE SName = 'MemberInfoLastImportedTime'