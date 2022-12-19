/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_DomainControl_Sel]
	@DomainControlId	INT = 0
	,@MarketIds			VARCHAR(400) = ''
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Domain Control - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20221110@Eddie: Support Block Market [RedmineID: #179537]
	Param's Explanation:
		- @MarketIds = 'en-GB,en-US,es-ES,hi-IN,id-ID,ja-JP,km-KH,ko-KR,th-TH,vi-VN,zh-CN,zh-TW'
*/

BEGIN
	SET NOCOUNT ON
	
	SET @MarketIds = ISNULL(@MarketIds, '')

	IF @DomainControlId <> 0
		SELECT
			a.Id 			AS DomainControlId
			,a.MarketId
			,d.MarketName
			,b.DomainId		AS AffDomainId
			,b.DomainName	AS AffDomain
			,c.DomainId		AS RedirectDomainId
			,c.DomainName	AS RedirectDomain
			,e.UserName		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
		FROM dbo.AffDomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.[12BetDomain] c WITH (NOLOCK) ON a.[12BetDomainId] = c.DomainId
			INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
			LEFT JOIN Users e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE a.Id = @DomainControlId
			AND a.IsDeleted = 0
	ELSE
		SELECT
			a.Id 			AS DomainControlId
			,a.MarketId
			,d.MarketName
			,b.DomainId		AS AffDomainId
			,b.DomainName	AS AffDomain
			,c.DomainId		AS RedirectDomainId
			,c.DomainName	AS RedirectDomain
			,e.UserName		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
		FROM dbo.AffDomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.[12BetDomain] c WITH (NOLOCK) ON a.[12BetDomainId] = c.DomainId
			INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
			LEFT JOIN Users e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE (',' + @MarketIds + ',' LIKE '%,' + a.MarketID + ',%')
			AND a.IsDeleted = 0
		ORDER BY
			d.MarketName
			,b.DomainName
END
GO