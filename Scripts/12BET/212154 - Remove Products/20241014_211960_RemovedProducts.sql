/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20241014@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Remove Products [RedmineId : #211960]

*/
USE Affiliate_12BET
GO

-- Products
SELECT TOP(1) *
INTO Products_DELETE_bk
FROM Products WITH (NOLOCK)

TRUNCATE TABLE Products_DELETE_bk

INSERT INTO Products_DELETE_bk
SELECT t.*
FROM (
DELETE Products
OUTPUT deleted.*
WHERE ProductId IN (13, 14, 17, 21, 22, 31, 34, 35)
) AS t
GO


-- APIProductSettings
SELECT TOP(1) *
INTO APIProductSettings_DELETE_bk
FROM APIProductSettings WITH (NOLOCK)

TRUNCATE TABLE APIProductSettings_DELETE_bk

INSERT INTO APIProductSettings_DELETE_bk
SELECT t.*
FROM (
DELETE APIProductSettings
OUTPUT deleted.*
WHERE ProductId IN (13, 14, 17, 21, 22, 31, 34, 35)
) AS t
GO


-- APIProductMappingSettings
SELECT TOP(1) *
INTO APIProductMappingSettings_DELETE_bk
FROM APIProductMappingSettings WITH (NOLOCK)

TRUNCATE TABLE APIProductMappingSettings_DELETE_bk

INSERT INTO APIProductMappingSettings_DELETE_bk
SELECT t.*
FROM (
DELETE APIProductMappingSettings
OUTPUT deleted.*
WHERE ProductId IN (13, 14, 17, 21, 22, 31, 34, 35)
) AS t
GO