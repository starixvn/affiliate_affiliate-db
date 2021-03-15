/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210205@Malcolm
	DB: DBAFF12BET-Affiliate_12BET 
	Task: Add new permission [RedminedId : #149213]
*/

USE Affiliate_12BET
GO

-- Add new roles
INSERT INTO dbo.Roles (RoleName)
VALUES ('Accounting Dept'), ('Other 1'), ('Other 2'), ('Other 3')

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy)
SELECT r.RoleId, f.FuncId, 0
FROM dbo.Functions f WITH (NOLOCK)
	CROSS JOIN dbo.Roles r WITH (NOLOCK)
WHERE r.RoleName IN ('Accounting Dept', 'Other 1', 'Other 2', 'Other 3')

--Export excel
INSERT INTO dbo.Functions (FuncName,DisplayName,Description,OrderId)
VALUES ('[ExportAffInfoExcel]', 'Export Excel - Affiliate Info', 'Export Excel - Affiliate Info', 30)
	  ,('[ExportPlayerDetailExcel]', 'Export Excel - Player Detail', 'Export Excel - Player Detail', 31)
	  ,('[ExportReportExcel]', 'Export Excel - Report', 'Export Excel - Report', 32)
	  ,('[AffAffiliate]', 'Affiliate', 'Affiliate', 33)
	  ,('[AffCustomerEdit]', 'Customer - Edit Affiliate', 'Customer - Edit Affiliate', 34)
	  ,('[EmailHistory]', 'Email History', 'Email History', 35)

UPDATE dbo.Functions WITH(ROWLOCK)
	SET ParentId = FuncId, AllParentIds = CONVERT(VARCHAR(20), FuncId)
WHERE FuncName IN ('[AffAffiliate]', '[AffCustomerEdit]')

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy)
SELECT r.RoleId, f.FuncId, CASE WHEN r.RoleId = 1 THEN 3 ELSE 0 END AS Policy
FROM dbo.Roles r WITH(NOLOCK)
CROSS APPLY(
	SELECT FuncId
	FROM dbo.Functions WITH(NOLOCK)
	WHERE FuncName IN ('[ExportAffInfoExcel]', '[ExportPlayerDetailExcel]', '[ExportReportExcel]', '[AffCustomerEdit]', '[AffAffiliate]')
) AS f

DECLARE @ParentExport INT, @ParentAffiliate INT 

SELECT @ParentExport = FuncId FROM Functions WITH(NOLOCK) WHERE FuncName = '[ExportExcel]'
SELECT @ParentAffiliate = FuncId FROM Functions WITH(NOLOCK) WHERE FuncName = '[AffAffiliate]'

UPDATE dbo.Functions WITH(ROWLOCK)
	SET ParentId = @ParentExport, AllParentIds = CONVERT(VARCHAR(20), @ParentExport)
WHERE FuncName IN ('[ExportAffInfoExcel]', '[ExportPlayerDetailExcel]', '[ExportReportExcel]')

UPDATE dbo.Functions WITH(ROWLOCK)
	SET ParentId = @ParentAffiliate, AllParentIds = CONVERT(VARCHAR(20), @ParentAffiliate)
WHERE FuncName IN ('[Affiliate]', '[Payment]', '[CommissionGroup]', '[EmailHistory]')