/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231114@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Add new permission for Marketing Team Note [RedmineId : #195391]
*/
-- Policy: 0: Not allow, 1: Read, 3: Host
DECLARE @Id INT, @OrderId INT

SELECT @OrderId = OrderId
FROM Functions WITH (NOLOCK)
WHERE FuncName = '[Note]'

UPDATE f WITH (ROWLOCK, UPDLOCK)
SET OrderId = OrderId + 1
FROM Functions f
WHERE OrderId > @OrderId

SET @OrderId = @OrderId + 1
-- order after function [Note]

INSERT INTO Functions (FuncName, DisplayName, Description, ParentId, AllParentIds, CreatedDate, UpdatedDate, Creator, OrderId)
VALUES ('[MarketingTeamNote]', 'Marketing Team Note', 'Marketing Team Note', NULL, NULL, GETDATE(), GETDATE(), NULL, @OrderId)

SELECT @Id = SCOPE_IDENTITY()

UPDATE Functions
SET ParentId = @Id, AllParentIds = @Id
WHERE FuncId = @Id 

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
VALUES (1, @Id, 3, NULL)

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
SELECT RoleId, @Id, 0, NULL
FROM dbo.Roles WITH(NOLOCK)
WHERE RoleId <> 1
GO