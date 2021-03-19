/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210312@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update IsShow of log action
*/

DECLARE @TABLE TABLE (Description NVARCHAR(MAX))
INSERT INTO @TABLE (Description)
VALUES
('Register account')
,('Update Login Status')
,('Forgot Password')
,('Recover Password')
,('Update user information')
,('Update user information')
,('Approve an affiliate')
,('Update user information')
,('Update payment request')
,('Assign affiliate to commission group')
,('Update favorite affiliate')
,('Update affiliate password')
,('Adjustment')
,('Update Verification Count after failed login 5 times')
,('Adjustment')
,('Update Preferred Language')
,('Update Status')
,('Update affiliate type')
,('Update payment request')
,('Update status')
,('Update remove status')
,('User note')
,('Payout')
,('New Email From Affiliate')
,('Update a note')
,('Update affiliate password')
,('Remove Affiliate Email')

UPDATE l WITH(ROWLOCK)
	SET l.IsShow = 1
FROM LogAction l 
	INNER JOIN @TABLE t ON t.Description = l.Description
