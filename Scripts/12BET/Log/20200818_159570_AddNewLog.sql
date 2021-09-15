/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20200818@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new log
*/

INSERT INTO dbo.LogType (TypeName, Description)
VALUES ('ProcessingRequest', 'Processing Request')

DECLARE @LogTypeId INT

SELECT @LogTypeId = TypeID FROM dbo.LogType WITH(NOLOCK) WHERE TypeName = 'ProcessingRequest'

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description, IsShow)
VALUES (1022, @LogTypeId, 'Aff_Admin_ProcessingRequest_Ins', 'Add Processing Request', 1)
	,(1023, @LogTypeId, 'Aff_Admin_ProcessingRequest_Upd', 'Update Processing Request', 1)
	,(1024, @LogTypeId, 'Aff_Admin_ProcessingRequest_Del', 'Remove Processing Request', 1)