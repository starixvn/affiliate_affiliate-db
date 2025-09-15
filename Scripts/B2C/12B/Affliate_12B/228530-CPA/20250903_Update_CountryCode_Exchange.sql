/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250903@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: CountryCode - Exchange [RedmineID: #237540]
*/
USE Affiliate_12B

-- Exchange: Add CountryCode column
ALTER TABLE Exchange
ADD CountryCode varchar(5) NULL;
GO

-- TPExchange: Add CountryCode column
ALTER TABLE TPExchange
ADD CountryCode varchar(5) NULL;
GO

UPDATE Exchange SET CountryCode = 'MY' WHERE ExchangeId = 2;
UPDATE Exchange SET CountryCode = 'US' WHERE ExchangeId = 3;
UPDATE Exchange SET CountryCode = 'TH' WHERE ExchangeId = 4;
UPDATE Exchange SET CountryCode = 'CN' WHERE ExchangeId = 13;
UPDATE Exchange SET CountryCode = 'ID' WHERE ExchangeId = 15;
UPDATE Exchange SET CountryCode = 'KR' WHERE ExchangeId = 45;
UPDATE Exchange SET CountryCode = 'VN' WHERE ExchangeId = 51;
UPDATE Exchange SET CountryCode = 'IN' WHERE ExchangeId = 61;
UPDATE Exchange SET CountryCode = 'BD' WHERE ExchangeId = 97;

GO

UPDATE te SET te.CountryCode = e.CountryCode
FROM Exchange e  WITH (ROWLOCK, UPDLOCK)
INNER JOIN TpExchange te ON e.ExchangeId = te.ExchangeId
GO