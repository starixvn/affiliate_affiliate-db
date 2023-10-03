/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20230828@Sally
	DB: DBAFFN88-Affiliate_N88

	Task: Affiliate - Support VND, BDT, INR currency on Base Currency filter [RedmineID: #193235]
	Step 1:
		- Config base currencies BDT, INR, VND
*/
-- Run only Affiliate_N88
USE Affiliate_N88
GO
	IF NOT EXISTS(
		SELECT 1
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName IN ('AFF_BaseCurrencies')
			AND SValue LIKE '%,74:BDT,61:INR,51:VND%'
	)
	BEGIN
		UPDATE S SET S.SValue = SValue + ',74:BDT,61:INR,51:VND'
		FROM dbo.SystemSettings S WITH (ROWLOCK)
		WHERE SName IN ('AFF_BaseCurrencies')
	END
GO

