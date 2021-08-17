/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210818@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new permission for Processing Request [RedmineId : #159570]
*/

DECLARE @FuncId INT, @FuncIdMarket INT, @FuncIdManage INT

INSERT INTO dbo.Functions(FuncName, DisplayName, Description, CreatedDate, UpdatedDate, Creator, OrderId)
VALUES ('[ProcessingRequest]', 'Processing Request', 'Processing Request', GETDATE(), GETDATE(), NULL, 39)
	,('[ProcessingRequestMarketingRole]', 'Processing Request - Marketing role', 'Processing Request - Marketing role', GETDATE(), GETDATE(), NULL, 40)
	,('[ProcessingRequestManagementRole]', 'Processing Request - Management role', 'Processing Request - Management role', GETDATE(), GETDATE(), NULL, 41)

SELECT @FuncId = FuncId FROM dbo.Functions WITH(NOLOCK) WHERE FuncName = '[ProcessingRequest]'
SELECT @FuncIdMarket = FuncId FROM dbo.Functions WITH(NOLOCK) WHERE FuncName = '[ProcessingRequestMarketingRole]'
SELECT @FuncIdManage = FuncId FROM dbo.Functions WITH(NOLOCK) WHERE FuncName = '[ProcessingRequestManagementRole]'

UPDATE dbo.Functions WITH(ROWLOCK)
	SET ParentId = @FuncId, AllParentIds = CONVERT(VARCHAR(20), @FuncId)
WHERE FuncName IN ('[ProcessingRequest]', '[ProcessingRequestMarketingRole]', '[ProcessingRequestManagementRole]')

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
VALUES (1, @FuncId, 3, NULL)
	,(1, @FuncIdMarket, 3, NULL)
	,(1, @FuncIdManage, 3, NULL)

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
SELECT RoleId, @FuncId, 0, NULL
FROM dbo.Roles WITH(NOLOCK)
WHERE RoleId <> 1

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
SELECT RoleId, @FuncIdMarket, 0, NULL
FROM dbo.Roles WITH(NOLOCK)
WHERE RoleId <> 1

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
SELECT RoleId, @FuncIdManage, 0, NULL
FROM dbo.Roles WITH(NOLOCK)
WHERE RoleId <> 1

/*
[ProcessingRequestMarketingRole]
[ProcessingRequestManagementRole]
*/

