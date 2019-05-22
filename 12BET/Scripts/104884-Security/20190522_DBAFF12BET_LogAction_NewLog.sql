USE [Affiliate_12BET]
GO

/*
	Created: 20190522@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: LogAction - Add new log action for Update Verification Count after failed login 5 times
*/

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description)
VALUES (12, 13, 'Aff_User_VerificationUpd', 'Update Verification Count after failed login 5 times')
GO