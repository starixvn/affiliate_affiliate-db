/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_DomainControl_Sel]
	@DomainControlId		INT = 0
	,@TargetCountryCodes	VARCHAR(100) = ''
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Domain Control - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20221110@Eddie: Support Block Market [RedmineID: #179537]
		- 20231027@Eddie: Change Markets to TargetCountries [RedmineID: #181590]
	Param's Explanation:
		- @MarketIds = 'en-GB,en-US,es-ES,hi-IN,id-ID,ja-JP,km-KH,ko-KR,th-TH,vi-VN,zh-CN,zh-TW' >>>>> removed
		- @TargetCountryCodes = 'MY,BD,IN,ID,JP,KH,KR,TH,VN,CN'
			Note: old data of TargetCountryCode is empty with language belong to ( 'English (Europe)', 'Spanish' )
*/

BEGIN
	SET NOCOUNT ON
	
	SET @TargetCountryCodes = ISNULL(@TargetCountryCodes, '')

	IF @DomainControlId <> 0
		SELECT
			a.Id 			AS DomainControlId
			,tc.CountryCode AS TargetCountryCode
			,tc.CountryName	AS TargetCountryName
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
			INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON a.MarketID = tc.MarketID AND a.TargetCountryCode = tc.CountryCode
			LEFT JOIN Users e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE a.Id = @DomainControlId
		  AND a.IsDeleted = 0
	ELSE
		SELECT
			a.Id 			AS DomainControlId
			,tc.CountryCode AS TargetCountryCode
			,tc.CountryName	AS TargetCountryName
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
			INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON a.MarketID = tc.MarketID AND a.TargetCountryCode = tc.CountryCode
			LEFT JOIN Users e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE (',' + @TargetCountryCodes + ',' LIKE '%,' + tc.CountryCode + ',%')
		  AND a.IsDeleted = 0
		ORDER BY tc.CountryName ,b.DomainName
END
GO