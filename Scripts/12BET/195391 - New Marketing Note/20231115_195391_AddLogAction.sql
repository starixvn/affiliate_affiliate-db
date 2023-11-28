/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231115@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Insert LogAction for Insert/Update Marketing Note [RedmineId : #195391]
*/
DECLARE @ActionID INT

SELECT @ActionID = MAX(ActionId)
FROM dbo.LogAction WITH (NOLOCK)

SELECT @ActionID = @ActionID + 1

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description, IsShow)
VALUES (@ActionID, 11, 'Aff_Admin_AffiliateMarketingNote_Ins', 'Insert a Marketing Team note', 1)

SELECT @ActionID = @ActionID + 1

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description, IsShow)
VALUES (@ActionID, 11, 'Aff_Admin_AffiliateMarketingNote_Upd', 'Update a Marketing Team note', 1)
GO