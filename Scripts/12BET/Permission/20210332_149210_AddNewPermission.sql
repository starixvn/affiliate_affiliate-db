/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210528@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new permission
*/

INSERT INTO dbo.Functions(FuncName, DisplayName, Description, ParentId, AllParentIds, CreatedDate, UpdatedDate, Creator, OrderId)
VALUES ('[RegisteredMembers]', 'Registered Members', 'Registered Members', NULL, NULL, GETDATE(), GETDATE(), NULL, 38)

DECLARE @FunctionId INT

SELECT @FunctionId = FuncId FROM dbo.Functions WITH(NOLOCK) WHERE FuncName = '[RegisteredMembers]'

UPDATE dbo.Functions WITH(ROWLOCK)
	SET ParentId = @FunctionId, AllParentIds = @FunctionId
WHERE FuncId = @FunctionId

INSERT INTO dbo.RoleFunction(RoleId, FuncId, Policy, Creator)
VALUES (1, @FunctionId, 3, NULL)

INSERT INTO dbo.RoleFunction(RoleId, FuncId, Policy, Creator)
SELECT RoleId, @FunctionId, 0, NULL
FROM Roles WITH(NOLOCK)
WHERE RoleId <> 1


UPDATE dbo.Functions WITH(ROWLOCK)
	SET Description = 'Member Name', DisplayName = 'Member Name'
WHERE FuncName = '[AffMemberName]'
--AffMemberName
