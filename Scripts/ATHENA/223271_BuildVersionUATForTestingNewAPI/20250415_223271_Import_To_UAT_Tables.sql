/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Revisions:
		- 20250415@Sophia: Build version UAT for testing new API [Redmine #223271]
*/
-- Import data into MemberInfo_UAT
INSERT INTO MemberInfo_UAT (
	UserName,
	DepositCustID,
	Btag,
	AffID,
	ClickID,
	Currency,
	CountryID,
	RegisteredDate,
	CreatedDate,
	IBCUsername,
	Email,
	FirstName,
	LastName,
	Phone,
	Address,
	IsRemoved,
	AffAffectedDate
)
SELECT top 1000 
	UserName,
	DepositCustID,
	Btag,
	AffID,
	ClickID,
	Currency,
	CountryID,
	RegisteredDate,
	CreatedDate,
	IBCUsername,
	Email,
	FirstName,
	LastName,
	Phone,
	Address,
	IsRemoved,
	AffAffectedDate
FROM MemberInfo WITH (NOLOCK)
ORDER BY CreatedDate DESC;

-- Import data into CurrencyConverter_UAT
INSERT INTO CurrencyConverter_UAT (
	PartnerCurrency,
	ExchangeID,
	ApplicationID
)
SELECT 
	PartnerCurrency,
	ExchangeID,
	ApplicationID
FROM CurrencyConverter WITH (NOLOCK);

-- Import data into AffInfo_UAT
INSERT INTO AffInfo_UAT (
	AffID,
	TotalMembers,
	DomainReferrer
)
SELECT  
	AffID,
	TotalMembers,
	DomainReferrer
FROM AffInfo WITH (NOLOCK)
;

-- Import data into ClickStatistics_UAT
INSERT INTO ClickStatistics_UAT (
	ClickID,
	AffID,
	DomainReferrer,
	[Date],
	SportCode,
	LanguageCode,
	ClickCount,
	IP
)
SELECT TOP 1000
	ClickID,
	AffID,
	DomainReferrer,
	[Date],
	SportCode,
	LanguageCode,
	ClickCount,
	IP
FROM ClickStatistics WITH (NOLOCK)
ORDER BY [Date] DESC;

