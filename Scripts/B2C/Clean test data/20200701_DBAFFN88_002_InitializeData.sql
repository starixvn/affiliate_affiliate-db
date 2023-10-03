/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200701@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Clean test data

	Step 2: Re-initialize data
*/

USE Affiliate_N88
GO

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest,ReleasedDate,RefProductId,DataSource)
SELECT Type AS ProductId, TypeName AS ProductName,'',0,1,0,'2020-07-01',Type AS RefProductId,'TpBetRecord' AS DataSource
FROM bodb_N88.dbo.TpGameType WITH (NOLOCK)
GO

INSERT INTO dbo.CommGroup (GroupName,Description,Creator,CreatedDate,IsPrivate,IsDeleted)
VALUES ('Default', 'Default System Revenue Group', 1000000001, GETDATE(), 0, 0)
		,('No Revenue Share', 'Group for all zero revenue share/closed affiliates', 1000000001, GETDATE(), 0, 0)
GO

INSERT INTO dbo.DeductionSetting (GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,NextGroupProductId,NextDeductedPercentage)
SELECT cg.GroupId,d.DeductionId,p.ProductId,1,d.DeductedPercentage,1,d.DeductedPercentage
FROM dbo.Deductions d WITH (NOLOCK)
	CROSS JOIN dbo.Products p WITH (NOLOCK)
	CROSS JOIN dbo.CommGroup cg WITH (NOLOCK)
WHERE d.DeductionId = 10
UNION ALL
SELECT cg.GroupId,d.DeductionId,0,1,d.DeductedPercentage,1,d.DeductedPercentage
FROM dbo.Deductions d WITH (NOLOCK)
	CROSS JOIN dbo.CommGroup cg WITH (NOLOCK)
WHERE d.DeductionId IN (11, 12)
GO

INSERT INTO dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage)
SELECT GroupId,'2020-07-31',DeductionId,ProductId,GroupProductId,DeductedPercentage
FROM dbo.DeductionSetting WITH (NOLOCK)
GO

INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
VALUES (1, 1, 0, 2500, 5, 1000000000, 0.25)
		,(1, 2, 2501, 40000, 5, 1000000000, 0.35)
		,(1, 3, 40001, 100000000000000, 5, 1000000000, 0.45)
		,(2, 1, 0, 100000000000000, 0, 1000000000, 0)
GO

INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
SELECT GroupId,'2020-07-31',TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
FROM dbo.TierSetting WITH (NOLOCK)
GO

INSERT INTO dbo.LandingPage (PageName, PageCode, IsDeleted)
VALUES ('Home', 'home', 0)
		,('Signup', 'signup', 0)
GO

INSERT INTO dbo.TransType (TypeId,TypeName,TypeDesc)
VALUES (201, 'Monthly Earning', 'Affiliate Monthly Earning Transfer')
		,(202, 'Payment', 'Affiliate Payment')
		,(203, 'Adjustment', 'Affiliate Balance Adjustmentr')
		,(204, 'Revenue Share', 'Affiliate Monthly Revenue Share Transfer')
GO

INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('AFF_BalPlayerAUD','N88AFFPlayerAUD')
		,('AFF_BalPlayerCHF','N88AFFPlayerCHF')
		,('AFF_BalPlayerEURO','N88AFFPlayerEURO')
		,('AFF_BalPlayerGBP','N88AFFPlayerGBP')
		,('AFF_BalPlayerIN','N88AFFPlayerIN')
		,('AFF_BalPlayerINH','N88AFFPlayerINH')
		,('AFF_BalPlayerINR','N88AFFPlayerINR')
		,('AFF_BalPlayerJPY','N88AFFPlayerJPY')
		,('AFF_BalPlayerRM','N88AFFPlayerRM')
		,('AFF_BalPlayerRMB','N88AFFPlayerRMB')
		,('AFF_BalPlayerSD$','N88AFFPlayerSD$')
		,('AFF_BalPlayerTB','N88AFFPlayerTB')
		,('AFF_BalPlayerUS$','N88AFFPlayerUS$')
		,('AFF_BalPlayerUUS','N88AFFPlayerUUS')
		,('AFF_BalPlayerWON','N88AFFPlayerWON')
		,('AFF_BaseCurrencies','2:MYR,3:USD,43:THB,34:IDR,13:CNY')
		,('AFF_CommissionDate','2020-05-31')
		,('AFF_SupportedCurrencies','3:USD,2:MYR,6:EUR,12:GBP,13:CNY,15:IDR,32:JPY,45:KRW,4:THB,20:UUS')
		,('AffCurrency','3')
		,('BrandName','Nova88')
		,('LastImportedTime_ExchangeOanda','2020-07-01 00:00:00')
		,('LaunchDate','2020-07-01')
		,('MaxSubLevel','4')
		,('MemberInfoLastImportedTime','2020-07-01 00:00:00')
		,('Payment_Method','Player:Nova88 Player Account')
		,('Payment_MinAmount','100')
		,('SiteName','N88')
		,('SoftLaunchDate','2020-07-01')
		,('TimeZone','8')
GO