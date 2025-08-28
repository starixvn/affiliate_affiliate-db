/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Domain_Sel]
	@AffID INT
	,@TargetCountryCode	VARCHAR(5) = ''
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: List aff domain

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250402@Lewis: Include Specific Domain [RedmineID: #221035]
		- 20250417@Lewis: Add BlockTargetCountry [RedmineID: #223644]
		- 20250523@Lewis: Add new column RedirectDomain [RedmineID: #227130]
		- 20250721@Eddie: Add new condition [RedmineID: #233219]
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @CutOffDate DATETIME = '20250213', @DealId INT

	CREATE TABLE #Result (
		DomainID 		INT -- AffDomainId
		,DomainName 	NVARCHAR(200) -- AffDomainName
		,IsSSL 			BIT -- AffDomainIsSSL
		,CreateDate 	DATETIME
		,IsSpecific 	BIT
		,RedirectDomain NVARCHAR(200) -- LicenseeDomainName
		,IsMobile 		BIT
	)

	SELECT @DealId = GroupId FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffID

	-- TODO: Specific Domain
	CREATE TABLE #SpecificDomainControl (
		AffId 				 INT
		,AffDomainId 		 INT
		,AffDomainName 		 NVARCHAR(200)
		,AffDomainIsSSL 	 BIT
		,LicenseeDomainName  NVARCHAR(200)
		,LicenseeDomainIsSSL BIT
		,Status 			 BIT
		,CreatedDate 		 DATETIME
		,IsMobile 			 BIT
	)

	INSERT INTO #SpecificDomainControl (
		AffId
		,AffDomainId
		,AffDomainName
		,AffDomainIsSSL
		,LicenseeDomainName
		,LicenseeDomainIsSSL
		,Status
		,CreatedDate
		,IsMobile
	)
	SELECT 
		s.AffId
		,0
		,s.AffDomainName
		,s.AffDomainIsSSL
		,s.LicenseeDomainName
		,s.LicenseeDomainIsSSL
		,s.Status
		,s.CreatedDate
		,s.IsMobile
	FROM dbo.SpecificDomainControl s WITH (NOLOCK)
	WHERE s.AffId = @AffID
	  AND s.Status = 1 -->> both AffDomain and RedirectDomain are AVAILABLE
	
	-- Update #SpecificDomainControl => AffDomainId and CreateDate
	UPDATE s SET s.AffDomainId = ad.DomainId, s.CreatedDate = ad.CreateDate
	FROM #SpecificDomainControl s
		LEFT JOIN dbo.AffDomain ad ON s.AffDomainName = ad.DomainName
	WHERE ad.DomainId IS NOT NULL

	-- Insert into #Result
	INSERT INTO #Result (
		DomainID
		,DomainName
		,IsSSL
		,CreateDate
		,IsSpecific
		,RedirectDomain
		,IsMobile
	)
	SELECT 
		AffDomainId
		,AffDomainName
		,AffDomainIsSSL
		,CreatedDate
		,1
		,LicenseeDomainName
		,IsMobile
	FROM #SpecificDomainControl

	-- TODO: Normal Domain
	INSERT INTO #Result (
		DomainID
		,DomainName
		,IsSSL
		,CreateDate
		,IsSpecific
		,RedirectDomain
		,IsMobile
	)
	SELECT a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL, a.CreateDate, 0, ld.DomainName, b.IsMobile
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.DomainControl b WITH (NOLOCK) ON a.DomainID = b.AffDomainId 
		INNER JOIN dbo.LicenseeDomain ld WITH (NOLOCK) ON b.LicenseeDomainId = ld.DomainId
	WHERE b.Status = 1
		AND a.IsDeleted = 0
		AND b.IsDeleted = 0
		AND ld.IsDeleted = 0
		AND a.CreateDate >= @CutOffDate
		AND b.TargetCountryCode = @TargetCountryCode
		AND (
			b.IsExcluded = 1 AND b.DealIds = ''
		 OR b.IsExcluded = 1 AND ( ',' + b.DealIds + ',' NOT LIKE ('%,' + CONVERT(VARCHAR(10), @DealId) + ',%' ) )
		 OR b.IsExcluded = 0 AND b.DealIds = '0'
		 OR b.IsExcluded = 0 AND ( ',' + b.DealIds + ',' LIKE ('%,' + CONVERT(VARCHAR(10), @DealId) + ',%' ) )
		)

	-- TODO: Result
	;WITH cte_Specific AS (
		SELECT *
		FROM #Result
		WHERE IsSpecific = 1
	), cte_Normal AS (
		SELECT *
		FROM #Result
		WHERE IsSpecific = 0
	)
	SELECT DISTINCT
		ISNULL(a.DomainID, b.DomainID) 			    AS DomainID
		,ISNULL(a.DomainName, b.DomainName) 	    AS DomainName
		,ISNULL(a.IsSSL, b.IsSSL) 				    AS IsSSL
		,ISNULL(a.CreateDate, b.CreateDate) 		AS CreateDate
		,ISNULL(a.RedirectDomain, b.RedirectDomain) AS RedirectDomain
		,ISNULL(a.IsMobile, b.IsMobile) 			AS IsMobile
	FROM cte_Specific a
		FULL OUTER JOIN cte_Normal b ON a.DomainID = b.DomainID

	DROP TABLE #SpecificDomainControl
	DROP TABLE #Result

END
GO