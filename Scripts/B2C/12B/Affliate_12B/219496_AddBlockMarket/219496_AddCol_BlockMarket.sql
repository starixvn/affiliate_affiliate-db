/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250319@Lewis	
	Task: add column BlockMarket ==> AffDomain, LicenseeDomain
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250319@Lewis: Created [RedmineID: #219496]

*/
USE Affiliate_12B

ALTER TABLE AffDomain 
ADD BlockMarket VARCHAR(400) NULL

ALTER TABLE LicenseeDomain 
ADD BlockMarket VARCHAR(400) NULL