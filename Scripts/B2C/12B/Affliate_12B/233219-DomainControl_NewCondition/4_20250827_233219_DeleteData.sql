/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250729@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Delete specific domain control [RedmineID: #233219]
*/
USE Affiliate_12B
GO

SELECT *
INTO DEL_SpecificDomainControl_More
FROM dbo.SpecificDomainControl sdc WITH (NOLOCK)
WHERE AffId <> 92043844 AND AffDomainName  IN ('goto.168sure.com', 'goto.5689fun.com', 'goto.oli368.com')

DELETE dbo.SpecificDomainControl
WHERE AffId <> 92043844 AND AffDomainName  IN ('goto.168sure.com', 'goto.5689fun.com', 'goto.oli368.com')
GO