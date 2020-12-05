/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20201205@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8G-Affiliate_N8G
	Task: Manually clean data due to job failed

	use Affiliate_N88
	go
	use Affiliate_N8G
	go
*/
DELETE dbo.rptAffCommission WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate = '2020-11-30'

DELETE dbo.rptAffDeduction WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate = '2020-11-30'

DELETE dbo.AffTrans WITH (ROWLOCK, UPDLOCK)
WHERE TransDate = '2020-11-30'

-- Note: start job "Affiliate_N88: Summarize Data Monthly", "Affiliate_N88: Summarize Data Monthly" at step 3