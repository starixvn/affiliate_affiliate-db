/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200605@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Add column IDR, THB on Exchange/ExchangeOanda for Base currency on Client
*/

-- USE Affiliate_N88
-- USE Affiliate_N8B
-- USE Affiliate_N8G

-- 1. AffTrans
ALTER TABLE AffTrans
	DROP COLUMN Currency, ActualRate, AffExRate
GO
ALTER TABLE AffTrans
	ADD AffCurrency INT, AffRate FLOAT
GO

DECLARE @AffCurrency INT
SELECT  @AffCurrency = CASE WHEN DB_NAME() = 'Affiliate_N88' THEN 3 ELSE 51 END

UPDATE t WITH (ROWLOCK)
SET AffCurrency = @AffCurrency
	,AffRate = e.Rate
FROM AffTrans t
	CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (t.TransDate, @AffCurrency, 0) e
GO

-- 2. AffPayout
ALTER TABLE AffPayout
	DROP COLUMN IBCCustId, UserName, IBCUserName, AffExRate, MemberCurrency, MemberExRate
GO
ALTER TABLE AffPayout
	ADD Player_CustId INT, AffRate FLOAT
GO

UPDATE t WITH (ROWLOCK)
SET Player_CustId = c.CustId
	,AffRate = e.Rate
FROM AffPayout t
	LEFT JOIN bodb_N88.dbo.Customer c WITH (NOLOCK) ON t.Player_Username = c.Username
	CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (t.TransDate, t.AffCurrency, 0) e
GO

-- 3. AffDetail
ALTER TABLE AffDetail
	DROP COLUMN Player_IBCCustID
GO

ALTER TABLE AffDetail
	ADD Player_CustId INT
GO

UPDATE t WITH (ROWLOCK)
SET Player_CustId = c.CustId
FROM AffDetail t
	INNER JOIN bodb_N88.dbo.Customer c WITH (NOLOCK) ON t.Player_Username = c.Username
GO