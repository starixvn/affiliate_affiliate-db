/*<info serverAlias="DBAFF12B-Affiliate_12B" ></info>*/
/*  
	Created: 20250402@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Insert LogAction - Insert LogType - Create table SpecificDomain and Init Data

	Revisions:
		- 20250402@Lewis: Init script [RedmineID: #221035]
*/
USE Affiliate_12B
GO

INSERT INTO LogAction (
	ActionId
	,ActionTypeId
	,SPName
	,Description
)
SELECT 50,28,'Aff_Admin_SpecificDomainControl_Ins','Add new specific domain control' UNION ALL
SELECT 51,28,'Aff_Admin_SpecificDomainControl_Upd','Update specific domain control' UNION ALL
SELECT 52,28,'Aff_Admin_SpecificDomainControl_Del','Delete specific domain control' 


INSERT INTO LogType (
	TypeId
	,TypeName
	,Description
)
SELECT 28,'SpecificDomainControl','SpecificDomainControl'

-- Create table SpecificDomainControl

CREATE TABLE SpecificDomainControl(
    Id INT IDENTITY(1,1) CONSTRAINT PK_SpecificDomainControl PRIMARY KEY NONCLUSTERED,
    AffId INT NOT NULL,
    AffDomainName NVARCHAR(100) NOT NULL,
	AffDomainIsSSL BIT CONSTRAINT DF_SpecificDomainControl_AffDomainIsSSL DEFAULT (1) NOT NULL,
    LicenseeDomainName NVARCHAR(100) NOT NULL,
	LicenseeDomainIsSSL BIT CONSTRAINT DF_SpecificDomainControl_LicenseeDomainIsSSL DEFAULT (1) NOT NULL,
    Status BIT CONSTRAINT DF_SpecificDomainControl_Status DEFAULT (1) NOT NULL,
    CreatedBy INT NULL,
    CreatedDate DATETIME CONSTRAINT DF_SpecificDomainControl_CreatedDate DEFAULT (getdate()) NOT NULL,
    UpdatedBy INT NULL,
    UpdatedDate DATETIME NULL
)  ON [SettingData];

CREATE UNIQUE CLUSTERED INDEX IX_SpecificDomainControl_AffId_AffDomainName
ON SpecificDomainControl (AffId, AffDomainName) ON [SettingData];

--Insert into SpecificDomainControl
TRUNCATE TABLE SpecificDomainControl
INSERT INTO SpecificDomainControl(
	
	AffId
	,AffDomainName
	,LicenseeDomainName
	,CreatedBy
	,CreatedDate
	,UpdatedBy
	,UpdatedDate
)
SELECT a.AffId
		,f.AffDomain
		,REPLACE(LEFT(f.RedirectDomain, LEN(f.RedirectDomain) - CHARINDEX('/', REVERSE(f.RedirectDomain) + '/')), 'https://', '') 
		,1000000000
		,GETDATE()
		,1000000000
		,GETDATE()
FROM dbo.Aff_f_SpecificRedirectDomain() f
INNER JOIN AffInfo a WITH (NOLOCK)
	ON f.AffUsername = a.UserName
