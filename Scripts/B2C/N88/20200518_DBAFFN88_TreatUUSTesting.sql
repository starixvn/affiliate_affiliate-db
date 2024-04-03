/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200518@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Update for UUS testing
*/

UPDATE AffPayout WITH (ROWLOCK)
SET AffPayout = Amount
WHERE Player_Currency = 20
	AND AffPayout IS NULL