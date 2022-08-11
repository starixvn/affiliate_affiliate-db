/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220811@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Add new permission for Feedback [RedmineId : #175628]
*/
-- Policy: 0: Not allow, 1: Read, 3: Host
DECLARE @FuncId SMALLINT, @FeedbackParentId SMALLINT, @AddOrderId VARCHAR(1000)

SELECT @FeedbackParentId = FuncId
FROM dbo.Functions WITH (NOLOCK)
WHERE FuncName = '[AffAffiliate]'

SELECT TOP(1) @AddOrderId = OrderId + '1'
FROM dbo.Functions WITH (NOLOCK)
ORDER BY OrderId DESC

INSERT INTO dbo.Functions(FuncName, DisplayName, Description, ParentId, AllParentIds, CreatedDate, UpdatedDate, Creator, OrderId)
VALUES ('[Feedback]', 'Feedback Report', 'Feedback Report', @FeedbackParentId, NULL, GETDATE(), GETDATE(), NULL, @AddOrderId )

UPDATE dbo.Functions WITH(ROWLOCK)
	SET AllParentIds = CONVERT(VARCHAR(20), @FeedbackParentId)
WHERE FuncName IN ('[Feedback]')

SELECT @FuncId = FuncId
FROM dbo.Functions WITH (NOLOCK)
WHERE FuncName = '[Feedback]'

--
INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
VALUES (1, @FuncId, 3, NULL)
-- 

--
INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy, Creator)
SELECT RoleId, @FuncId, 0, NULL
FROM dbo.Roles WITH(NOLOCK)
WHERE RoleId <> 1
--
