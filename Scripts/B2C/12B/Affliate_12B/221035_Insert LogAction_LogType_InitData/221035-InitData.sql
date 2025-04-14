/*<info serverAlias="DBAFF12B-Affiliate_12B" ></info>*/
/*  
	Created: 20250402@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Create table SpecificDomain and Init Data

	Revisions:
		- 20250402@Lewis: Init script [RedmineID: #221035]
*/
USE Affiliate_12B
GO

TRUNCATE TABLE SpecificDomainControl

INSERT INTO SpecificDomainControl(
	
	AffId
	,AffDomainName
	,LicenseeDomainName
	,CreatedBy
	,CreatedDate
	
)
SELECT a.AffId
		,f.AffDomain
		,REPLACE(LEFT(f.RedirectDomain, LEN(f.RedirectDomain) - CHARINDEX('/', REVERSE(f.RedirectDomain) + '/')), 'https://', '') 
		,1000000000
		,GETDATE()
FROM dbo.Aff_f_SpecificRedirectDomain() f
INNER JOIN AffInfo a WITH (NOLOCK)
	ON f.AffUsername = a.UserName
