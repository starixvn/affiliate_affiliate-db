/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250721@Eddie	
	DB: DBAFF12B-Affiliate_12B
	Task: Add new column [RedmineID: #233219]
*/
USE Affiliate_12B
GO

ALTER TABLE dbo.DomainControl 
ADD IsMobile BIT NOT NULL CONSTRAINT DF_DomainControl_IsMobile DEFAULT(0)
  , IsExcluded BIT NOT NULL CONSTRAINT DF_DomainControl_IsExcluded DEFAULT(1)
  , DealIds NVARCHAR(MAX) NOT NULL CONSTRAINT DF_DomainControl_DealIds DEFAULT('')

ALTER TABLE dbo.LandingPage 
ADD IsMobile BIT NOT NULL CONSTRAINT DF_LandingPage_IsMobile DEFAULT(0)
  , IsExcluded BIT NOT NULL CONSTRAINT DF_LandingPage_IsExcluded DEFAULT(1)
  , DealIds NVARCHAR(MAX) NOT NULL CONSTRAINT DF_LandingPage_DealIds DEFAULT('')
GO

ALTER TABLE dbo.SpecificDomainControl 
ADD IsMobile BIT NOT NULL CONSTRAINT DF_SpecificDomainControl_IsMobile DEFAULT(0)
GO

DECLARE @NoComm_DealIds VARCHAR(10), @CPA_DealId VARCHAR(5)

SELECT @NoComm_DealIds = STRING_AGG(GroupId, ',')
FROM dbo.CommGroup WITH (NOLOCK)
WHERE GroupName IN ( N'NoCommission', N'NoCommission-Marketing group')

SELECT @CPA_DealId = CONVERT(VARCHAR(5), GroupId)
FROM dbo.CommGroup WITH (NOLOCK)
WHERE GroupName = N'NoCommission-CPA'

-- Initial data of LandingPage
UPDATE dbo.LandingPage WITH (ROWLOCK, UPDLOCK)
SET IsMobile = 1, IsExcluded = 0, DealIds = @NoComm_DealIds
WHERE IsDeleted = 0 AND PageCode LIKE '%12join%'

-- Initial data of SpecificDomainControl
UPDATE dbo.SpecificDomainControl WITH (ROWLOCK, UPDLOCK)
SET IsMobile = 1
WHERE LicenseeDomainName LIKE 'm.%'

-- DomainControl with normal
UPDATE dc WITH (ROWLOCK, UPDLOCK)
SET dc.IsMobile = 0, IsExcluded = 1, DealIds = @CPA_DealId
FROM dbo.DomainControl dc
	INNER JOIN LicenseeDomain ld WITH (NOLOCK) ON dc.LicenseeDomainId = ld.DomainId
WHERE dc.IsDeleted = 0
  AND ld.IsDeleted = 0
  AND ld.DomainName NOT LIKE 'm.%'

-- DomainControl with mobile only 
UPDATE dc WITH (ROWLOCK, UPDLOCK)
SET dc.IsMobile = 1, IsExcluded = 0, DealIds = @NoComm_DealIds
FROM dbo.DomainControl dc
	INNER JOIN LicenseeDomain ld WITH (NOLOCK) ON dc.LicenseeDomainId = ld.DomainId
WHERE dc.IsDeleted = 0
  AND ld.IsDeleted = 0
  AND ld.DomainName LIKE 'm.%'

-- Insert data with specific domain
DECLARE @AffDomainId INT = 0
	   ,@AffDomainName NVARCHAR(50) = ''
	   ,@LicenseeDomainId INT = 0
	   ,@LicenseeDomainName NVARCHAR(50) = ''
	   ,@Id INT = 1

DECLARE @DomainControl_tmp TABLE (Id INT, AffDomainName NVARCHAR(50), LicenseeDomainName NVARCHAR(50))

INSERT INTO @DomainControl_tmp (Id, AffDomainName, LicenseeDomainName)
VALUES (1, N'goto.168sure.com', N'www.qws889.com')
	  ,(2, N'goto.5689fun.com', N'www.mvm88.com')
      ,(3, N'goto.oli368.com', N'www.12vibe5678.com')

WHILE EXISTS ( SELECT 1 FROM @DomainControl_tmp WHERE Id = @Id )
BEGIN
	SELECT @AffDomainName = AffDomainName
		  ,@LicenseeDomainName = LicenseeDomainName
	FROM @DomainControl_tmp
	WHERE Id = @Id

	-- Insert AffDomain
	INSERT INTO dbo.AffDomain([DomainName], [CreateDate], [ModifyDate], [Creator], [IsDeleted], [IsSSL], [BlockTargetCountry])
	SELECT t.DomainName AS DomainName
	      ,GETDATE() 	AS CreateDate
		  ,GETDATE() 	AS ModifyDate
		  ,1000000000 	AS Creator
		  ,0 			AS IsDeleted
		  ,1 			AS IsSSL
		  ,'' 			AS BlockTargetCountry
	FROM (
		SELECT @AffDomainName AS DomainName
	) AS t
		LEFT JOIN dbo.AffDomain ad WITH (NOLOCK) ON ad.DomainName = t.DomainName
												AND ad.IsDeleted = 0
	WHERE ad.DomainName IS NULL


	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @AffDomainId = DomainId FROM dbo.AffDomain WHERE DomainName = @AffDomainName AND IsDeleted = 0
	END
	ELSE SELECT @AffDomainId = SCOPE_IDENTITY()


	-- Insert LicenseeDomain
	INSERT INTO dbo.LicenseeDomain([DomainName], [CreateDate], [ModifyDate], [Creator], [DeviceType], [IsDeleted], [W3Prefix], [IsSSL], [BlockTargetCountry])
	SELECT h.DomainName AS DomainName
	      ,GETDATE() 	AS CreateDate
		  ,GETDATE() 	AS ModifyDate
		  ,1000000000 	AS Creator
		  ,0 			AS DeviceType
		  ,0 			AS IsDeleted
		  ,'www' 		AS W3Prefix
		  ,1 			AS IsSSL
		  ,'' 			AS BlockTargetCountry
	FROM (
		SELECT @LicenseeDomainName AS DomainName
	) AS h
		LEFT JOIN dbo.LicenseeDomain ld WITH (NOLOCK) ON ld.DomainName = h.DomainName
													 AND ld.IsDeleted = 0
	WHERE ld.DomainName IS NULL


	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @LicenseeDomainId = DomainId FROM dbo.LicenseeDomain WHERE DomainName = @LicenseeDomainName AND IsDeleted = 0
	END
	ELSE SELECT @LicenseeDomainId = SCOPE_IDENTITY()


	-- Insert DomainControl
	INSERT INTO dbo.DomainControl([AffDomainId], [LicenseeDomainId], [MarketId], [CreateDate], [ModifyDate], [Creator], [Status], [DeviceType], [IsDeleted], [TargetCountryCode], [IsExcluded], [DealIds], [IsMobile])
	SELECT @AffDomainId 		AS AffDomainId
		  ,@LicenseeDomainId 	AS LicenseeDomainId
		  ,g.MarketID 			AS MarketId
		  ,GETDATE() 			AS CreateDate
		  ,GETDATE() 			AS ModifyDate
		  ,1000000000 			AS Creator
		  ,1 					AS Status
		  ,0 					AS DeviceType
		  ,0 					AS IsDeleted
		  ,g.CountryCode 		AS TargetCountryCode
		  ,0 					AS IsExcluded
		  ,@CPA_DealId 			AS DealIds
		  ,0 					AS IsMobile
	FROM (
		SELECT tc.CountryCode, tc.MarketID
		FROM dbo.TargetCountry tc WITH (NOLOCK)
		WHERE tc.OrderNo IS NOT NULL
		  AND NOT EXISTS ( SELECT 1 FROM dbo.Market m WITH (NOLOCK) WHERE m.MarketId =  tc.MarketID AND m.IsDeleted = 1 )
	) AS g
		LEFT JOIN dbo.DomainControl dc WITH (NOLOCK) ON dc.TargetCountryCode = g.CountryCode
													AND dc.AffDomainId = @AffDomainId
													AND dc.IsDeleted = 0
	WHERE dc.TargetCountryCode IS NULL
	   OR dc.AffDomainId IS NULL

	WAITFOR DELAY '00:00:00.280'

	SELECT @Id += 1
END
GO

-- Insert SystemSettings with default LandingPage
INSERT INTO dbo.SystemSettings([SName], [SValue])
SELECT t.SName, t.SValue
FROM (
		VALUES ('LandingPage', '19')
) AS t(SName, SValue)
	LEFT JOIN dbo.SystemSettings s WITH (NOLOCK) ON s.SName = t.SName
WHERE s.SName IS NULL
