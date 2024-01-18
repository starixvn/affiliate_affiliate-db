/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231103@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Add new permission for Target Country [RedmineId : #181590]
*/
-- Policy: 0: Not allow, 1: Read, 3: Host
DECLARE @Id INT, @OrderId INT

SELECT @OrderId = MAX(OrderId) + 1
FROM Functions WITH (NOLOCK)

INSERT INTO Functions (FuncName, DisplayName, Description, ParentId, AllParentIds, CreatedDate, UpdatedDate, Creator, OrderId)
VALUES ('[TargetCountry]', 'Target Country', 'Target Country', NULL, NULL, GETDATE(), GETDATE(), NULL, @OrderId)

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