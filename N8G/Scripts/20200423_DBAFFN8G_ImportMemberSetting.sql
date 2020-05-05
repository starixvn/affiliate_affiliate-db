USE Affiliate_N8G
GO

UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = '2020-04-20'
WHERE SName = 'MemberInfoLastImportedTime'