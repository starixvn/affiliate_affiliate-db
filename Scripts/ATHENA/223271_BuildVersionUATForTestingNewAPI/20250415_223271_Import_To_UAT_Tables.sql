/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Revisions:
		- 20250415@Sophia: Build version UAT for testing new API [Redmine #223271]
*/
-- Import data into MemberInfo_UAT
truncate table MemberInfo_UAT 

INSERT INTO MemberInfo_UAT (
	UserName,
	AffID,
	CreatedDate,
	RegisteredDate,
	DepositCustID,
	Currency,
	FirstName,
	LastName,
	Email,
	IsRemoved,
	IBCCustID,
	IBCUserName,
	Recommend,
	Btag,
	ClickID,
	CountryID,
	Phone,
	Address,
	AffAffectedDate
)
SELECT  TOP 5000
	UserName,
	AffID,
	CreatedDate,
	RegisteredDate,
	DepositCustID,
	Currency,
	FirstName,
	LastName,
	Email,
	IsRemoved,
	IBCCustID,
	IBCUserName,
	Recommend,
	Btag,
	ClickID,
	CountryID,
	Phone,
	Address,
	AffAffectedDate
FROM MemberInfo WITH (NOLOCK)
ORDER BY CreatedDate DESC;

-- Import data into CurrencyConverter_UAT
TRUNCATE TABLE CurrencyConverter_UAT 
INSERT INTO CurrencyConverter_UAT (
	ApplicationID,
	PartnerCurrency,
	ExchangeID,
	CreatedDate,
	PartnerExchangeID
)
SELECT 
	ApplicationID,
	PartnerCurrency,
	ExchangeID,
	CreatedDate,
	PartnerExchangeID
FROM CurrencyConverter WITH (NOLOCK);

-- Import data into AffInfo_UAT
truncate table AffInfo_UAT 
 
SET IDENTITY_INSERT AffInfo_UAT ON

INSERT INTO AffInfo_UAT (
	AffID,
	UserName,
	UserName2,
	FirstName,
	LastName,
	GroupID,
	Status,
	ApprovedDate,
	IsClosed,
	Currency,
	RegisteredDate,
	Email,
	Password,
	AffType,
	IsPageEnabled,
	Level,
	IsLocked,
	TestLevel,
	BF,
	TotalMembers
)
SELECT 
	AffID,
	UserName,
	UserName2,
	FirstName,
	LastName,
	GroupID,
	Status,
	ApprovedDate,
	IsClosed,
	Currency,
	RegisteredDate,
	Email,
	Password,
	AffType,
	IsPageEnabled,
	Level,
	IsLocked,
	TestLevel,
	BF,
	TotalMembers
FROM AffInfo WITH (NOLOCK) 

SET IDENTITY_INSERT AffInfo_UAT OFF
-- Import data into ClickStatistics_UAT

truncate table ClickStatistics_UAT 
GO
SET IDENTITY_INSERT ClickStatistics_UAT ON

INSERT INTO ClickStatistics_UAT (
	ClickID,
	AffID,
	UpdatedTime,
	IP,
	[Date],
	Browser,
	URLReferrer,
	DomainReferrer,
	OS,
	Device,
	BrowserVersion,
	BrowserResolution,
	BrowserLanguage,
	UserAgent,
	Country,
	LanguageCode,
	SportCode,
	RedirectURL,
	Status,
	ClickCount
)
SELECT 
	ClickID,
	AffID,
	UpdatedTime,
	IP,
	[Date],
	Browser,
	URLReferrer,
	DomainReferrer,
	OS,
	Device,
	BrowserVersion,
	BrowserResolution,
	BrowserLanguage,
	UserAgent,
	Country,
	LanguageCode,
	SportCode,
	RedirectURL,
	Status,
	ClickCount
FROM ClickStatistics WITH (NOLOCK) 


SET IDENTITY_INSERT ClickStatistics_UAT OFF