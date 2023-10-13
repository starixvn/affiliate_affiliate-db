/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230926@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Add new permission for Assign Affiliate [RedmineId : #180516]
*/
-- Policy: 0: Not allow, 1: Read, 3: Host
DECLARE @Id INT, @AddOrderId SMALLINT

SELECT TOP(1) @AddOrderId = OrderId + 1
FROM dbo.Functions WITH (NOLOCK)
ORDER BY OrderId DESC

INSERT INTO Functions (FuncName, DisplayName, Description, ParentId, AllParentIds, CreatedDate, UpdatedDate, Creator, OrderId)
VALUES ('[AssignAffiliate]', 'Assign Affiliate', 'Assign Affiliate', NULL, NULL, GETDATE(), GETDATE(), NULL, @AddOrderId)

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

