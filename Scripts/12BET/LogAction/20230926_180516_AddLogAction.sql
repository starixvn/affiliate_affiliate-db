/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230926@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Insert LogAction for assign affiliate feature [RedmineId : #180516]
*/
DECLARE @ActionID INT

SELECT @ActionID = MAX(ActionId)
FROM dbo.LogAction WITH (NOLOCK)

SELECT @ActionID = @ActionID + 1

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description, IsShow)
VALUES (@ActionID, 18, 'Aff_Admin_Assign_Ins', 'Admin assign affiliate for member', 1) -- ActionID: 1030
GO