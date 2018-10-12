USE [Affiliate_12BET]
GO

/*
	Created: 20181012@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add missing log - [RedmineID: #103116]
*/

INSERT INTO dbo.LogType (TypeName, Description)
SELECT lt.TypeName, lt.TypeName
FROM
(
	SELECT '12BetDomain' AS TypeName UNION ALL
	SELECT 'AffDomain' AS TypeName UNION ALL
	SELECT 'AffDomainControl' AS TypeName UNION ALL
	SELECT 'Password' AS TypeName UNION ALL
	SELECT 'Payout' AS TypeName UNION ALL
	SELECT 'UserInfo' AS TypeName UNION ALL
	SELECT 'Affiliate' AS TypeName UNION ALL
	SELECT 'AffInfo' AS TypeName UNION ALL
	SELECT 'CommissionGroup' AS TypeName UNION ALL
	SELECT 'Banner' AS TypeName UNION ALL
	SELECT 'Email' AS TypeName UNION ALL
	SELECT 'ExchangeRate' AS TypeName UNION ALL
	SELECT 'Message' AS TypeName UNION ALL
	SELECT 'LoginAdmin' AS TypeName UNION ALL
	SELECT 'LoginAffiliate' AS TypeName UNION ALL
	SELECT 'Member' AS TypeName UNION ALL
	SELECT 'UserNote' AS TypeName UNION ALL
	SELECT 'Adjustment' AS TypeName UNION ALL
	SELECT 'UserControl' AS TypeName
) AS lt
	LEFT JOIN dbo.LogType l WITH (NOLOCK) ON lt.TypeName = l.TypeName
WHERE l.TypeName IS NULL