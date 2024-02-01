/*<info serverAlias="DBCUST-bodb_Licensee"></info>*/
/*
	Created: 20240201@Sally
	DB: DBCUST-bodb_Licensee
	Task: Support new Aff Yashbet
		- Update BrandName for YashBet Licensee
*/

USE bodb_Licensee
GO

UPDATE l SET L.BrandName = 'YashBet'
FROM dbo.Licensees l WITH (UPDLOCK) 
WHERE L.LicenseeID = 50272
	AND ISNULL(l.BrandName,'') <> 'YashBet'
GO

SELECT *
FROM dbo.Licensees l WITH (UPDLOCK) 
WHERE L.LicenseeID = 50272
	AND l.BrandName = 'YashBet'
