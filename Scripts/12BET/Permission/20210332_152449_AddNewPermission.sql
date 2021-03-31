/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210331@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new permission
*/

INSERT INTO dbo.Functions(FuncName, DisplayName, Description, ParentId, AllParentIds, CreatedDate, UpdatedDate, Creator, OrderId)
VALUES ('[ViewLog]', 'View Log', 'View Log', NULL, NULL, GETDATE(), GETDATE(), NULL, 37)

DECLARE @FunctionId INT

SELECT @FunctionId = FuncId FROM dbo.Functions WITH(NOLOCK) WHERE FuncName = '[ViewLog]'

UPDATE dbo.Functions WITH(ROWLOCK)
	SET ParentId = @FunctionId, AllParentIds = @FunctionId
WHERE FuncId = @FunctionId

INSERT INTO dbo.RoleFunction(RoleId, FuncId, Policy, Creator)
VALUES (1, @FunctionId, 3, NULL)

INSERT INTO dbo.RoleFunction(RoleId, FuncId, Policy, Creator)
SELECT RoleId, @FunctionId, 0, NULL
FROM Roles WITH(NOLOCK)
WHERE RoleId <> 1
