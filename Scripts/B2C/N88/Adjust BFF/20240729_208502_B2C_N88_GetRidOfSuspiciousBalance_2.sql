/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*	
	Created: 20240729@Sally
	Task: N88 AFF - Get rid of suspicious balance [RedmineID: #208502]
	DB: DBAFFN88-Affiliate_N88
*/

USE Affiliate_N88
GO


UPDATE at SET Amount = at.Amount *(-1)
FROM dbo.AffTrans at WITH (UPDLOCK, ROWLOCK)
WHERE at.TransId = 19326


