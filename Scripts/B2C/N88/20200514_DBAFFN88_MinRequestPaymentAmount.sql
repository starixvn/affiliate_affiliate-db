/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200515@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Update min payment amount
*/

UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
SET SValue = '100'
WHERE SName = 'Payment_MinAmount'