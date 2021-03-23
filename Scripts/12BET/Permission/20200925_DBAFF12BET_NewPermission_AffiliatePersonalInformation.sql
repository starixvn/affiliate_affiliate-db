/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
USE Affiliate_12BET
GO

INSERT INTO dbo.Functions (FuncName, DisplayName, Description)
VALUES ('[AffPersonalInfo]', 'View Full Affiliate Personal Information', 'View Full Affiliate Personal Information')

UPDATE dbo.Functions WITH (ROWLOCK)
SET ParentId = FuncId, AllParentIds = CONVERT(VARCHAR(10), FuncId), OrderId = FuncId
WHERE FuncName = '[AffPersonalInfo]'

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy)
SELECT RoleId, FuncId, CASE WHEN r.RoleId = 1 THEN 3 ELSE 0 END Policy
FROM dbo.Roles r WITH (NOLOCK)
	CROSS JOIN dbo.Functions f WITH (NOLOCK)
WHERE f.FuncName = '[AffPersonalInfo]'

INSERT INTO dbo.UserFunction(CustId, FuncId, Policy)
SELECT CustId, FuncId, CASE WHEN u.RoleId = 1 THEN 3 ELSE 0 END Policy
FROM dbo.Users u WITH (NOLOCK)
	CROSS JOIN dbo.Functions f WITH (NOLOCK)
WHERE f.FuncName = '[AffPersonalInfo]'