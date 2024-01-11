/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/

/*
	Created: 20201002@Percy
	DB:
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Clean test data

	Step 2: Re-initialize data
*/

/*
USE Affiliate_N8B
USE Affiliate_N8G
*/

DECLARE @LaunchDate DATETIME
SELECT  @LaunchDate = '2020-10-01'

INSERT INTO dbo.Affiliate_User (CreateDate,Creator,GroupId,Closed,LoginCount,IPLogin,LastLogged,On_SessionId,UserName,UserPwd,RoleId,PwdExpiry,FirstName,LastName)
VALUES (@LaunchDate,0,1001,0,0,'',@LaunchDate,0,'AAStarixDBA','56E8A2D78170E87C928E480797CC73',10,'2022-12-31','Starix','DBA')
		,(@LaunchDate,1000000000,1001,0,0,'',@LaunchDate,0,'AAStarixDev','56E8A2D78170E87C928E480797CC73',6,'2022-12-31','Starix','Dev')
		,(@LaunchDate,1000000000,1001,0,0,'',@LaunchDate,0,'AAStarixQC01','56E8A2D78170E87C928E480797CC73',6,'2022-12-31','Starix','QC01')
		,(@LaunchDate,1000000000,1001,0,0,'',@LaunchDate,0,'AAStarixQC02','56E8A2D78170E87C928E480797CC73',6,'2022-12-31','Starix','QC02')
		,(@LaunchDate,1000000000,1001,0,0,'',@LaunchDate,0,'AAStarixBA','C268042478D7C70CCA806088317681',6,'2022-12-31','Starix','BA')
		,(@LaunchDate,1000000000,1001,0,0,'',@LaunchDate,0,'AAAnn','8898226B7448077D2C86ABD7682E8A',6,'2022-12-31','','')
		,(@LaunchDate,1000000000,1001,0,0,'',@LaunchDate,0,'AABen','56E8A2D78170E87C928E480797CC73',6,'2022-12-31','','')
		,(@LaunchDate,1000000000,1002,0,0,'',@LaunchDate,0,'AAJade','56E8A2D78170E87C928E480797CC73',6,'2022-12-31','Jade','')

INSERT INTO dbo.AffMemberPolicy (CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT u.CustId, f.FuncId, 3, @LaunchDate, @LaunchDate, 1000000000
FROM dbo.Affiliate_User u WITH (NOLOCK)
	CROSS JOIN dbo.AffFunctionInfo f WITH (NOLOCK)

UPDATE dbo.AffFunctionInfo WITH (ROWLOCK, UPDLOCK)
SET CreateDate = @LaunchDate, ModifyDate = @LaunchDate, Creator = 1000000000

UPDATE dbo.AffGroupInfo WITH (ROWLOCK, UPDLOCK)
SET CreateDate = @LaunchDate, ModifyDate = @LaunchDate, Creator = 1000000000

UPDATE dbo.AffGroupPolicy WITH (ROWLOCK, UPDLOCK)
SET CreateDate = @LaunchDate, ModifyDate = @LaunchDate, Creator = 1000000000

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest,ReleasedDate,RefProductId,DataSource)
SELECT Type AS ProductId, TypeName AS ProductName,'',0,1,0,@LaunchDate,Type AS RefProductId,'TpBetRecord' AS DataSource
FROM bodb_N88.dbo.TpGameType WITH (NOLOCK)

INSERT INTO dbo.CommGroup (GroupName,Description,Creator,CreatedDate,IsPrivate,IsDeleted)
VALUES ('Default', 'Default System Revenue Group', 1000000000, @LaunchDate, 0, 0)
		,('No Revenue Share', 'Group for all zero revenue share/closed affiliates', 1000000000, @LaunchDate, 0, 0)

INSERT INTO dbo.DeductionSetting (GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage)
SELECT cg.GroupId,d.DeductionId,p.ProductId,1,d.DeductedPercentage
FROM dbo.Deductions d WITH (NOLOCK)
	CROSS JOIN dbo.Products p WITH (NOLOCK)
	CROSS JOIN dbo.CommGroup cg WITH (NOLOCK)
WHERE d.DeductionId = 10
UNION ALL
SELECT cg.GroupId,d.DeductionId,0,1,d.DeductedPercentage
FROM dbo.Deductions d WITH (NOLOCK)
	CROSS JOIN dbo.CommGroup cg WITH (NOLOCK)
WHERE d.DeductionId IN (11, 12)

INSERT INTO dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage)
SELECT GroupId,'2020-10-31',DeductionId,ProductId,GroupProductId,DeductedPercentage
FROM dbo.DeductionSetting WITH (NOLOCK)

INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
VALUES (1, 1, 0, 2500, 5, 1000000000, 0.25)
		,(1, 2, 2501, 40000, 5, 1000000000, 0.35)
		,(1, 3, 40001, 100000000000, 5, 1000000000, 0.45)
		,(2, 1, 0, 100000000000, 0, 1000000000, 0)

INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
SELECT GroupId,'2020-10-31',TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
FROM dbo.TierSetting WITH (NOLOCK)

INSERT INTO dbo.LandingPage (PageName, PageCode, IsDeleted)
VALUES ('Home', 'home', 0)
		,('Signup', 'signup', 0)

INSERT INTO dbo.TransType (TypeId,TypeName,TypeDesc)
VALUES (201, 'Monthly Earning', 'Affiliate Monthly Earning Transfer')
		,(202, 'Payment', 'Affiliate Payment')
		,(203, 'Adjustment', 'Affiliate Balance Adjustmentr')
		,(204, 'Revenue Share', 'Affiliate Monthly Revenue Share Transfer')

IF DB_NAME() = 'Affiliate_N8B'
BEGIN
	INSERT INTO dbo.SystemSettings (SName, SValue)
	VALUES
		('AFF_BalPlayerAUD', 'N8BAFFPlayerAUD')
		,('AFF_BalPlayerCHF', 'N8BAFFPlayerCHF')
		,('AFF_BalPlayerEURO', 'N8BAFFPlayerEURO')
		,('AFF_BalPlayerGBP', 'N8BAFFPlayerGBP')
		,('AFF_BalPlayerIN', 'N8BAFFPlayerIN')
		,('AFF_BalPlayerINH', 'N8BAFFPlayerINH')
		,('AFF_BalPlayerINR', 'N8BAFFPlayerINR')
		,('AFF_BalPlayerRM', 'N8BAFFPlayerRM')
		,('AFF_BalPlayerRMB', 'N8BAFFPlayerRMB')
		,('AFF_BalPlayerSD$', 'N8BAFFPlayerSD$')
		,('AFF_BalPlayerTB', 'N8BAFFPlayerTB')
		,('AFF_BalPlayerUS$', 'N8BAFFPlayerUS$')
		,('AFF_BalPlayerUUS', 'N8BAFFPlayerUUS')
		,('AFF_BalPlayerWON', 'N8BAFFPlayerWON')
		,('AFF_BaseCurrencies', '51:VND,3:USD')
		,('AFF_CheckData_Bettrans', '2020-10-01')
		,('AFF_CommissionDate', '2020-09-30')
		,('AFF_SupportedCurrencies', '51:VND')
		,('AffCurrency', '51')
		,('BrandName', 'Bwing')
		,('LastImportedTime_ExchangeOanda', '2020-10-01')
		,('LaunchDate', '2020-10-01')
		,('MaxSubLevel', '4')
		,('MemberInfoLastImportedTime', '2020-10-01')
		,('Payment_Method', 'Player:Bwing Player Account,Moneybookers:Moneybookers,Wire:Wire Transfer')
		,('Payment_MinAmount', '2300')
		,('SiteName', 'N8B')
		,('SoftLaunchDate', '2020-10-01')
		,('TimeZone', '8')
END
ELSE IF DB_NAME() = 'Affiliate_N8G'
BEGIN
	INSERT INTO dbo.SystemSettings (SName, SValue)
	VALUES
		('AFF_BalPlayerAUD', 'N8GAFFPlayerAUD')
		,('AFF_BalPlayerCHF', 'N8GAFFPlayerCHF')
		,('AFF_BalPlayerEURO', 'N8GAFFPlayerEURO')
		,('AFF_BalPlayerGBP', 'N8GAFFPlayerGBP')
		,('AFF_BalPlayerIN', 'N8GAFFPlayerIN')
		,('AFF_BalPlayerINH', 'N8GAFFPlayerINH')
		,('AFF_BalPlayerINR', 'N8GAFFPlayerINR')
		,('AFF_BalPlayerRM', 'N8GAFFPlayerRM')
		,('AFF_BalPlayerRMB', 'N8GAFFPlayerRMB')
		,('AFF_BalPlayerSD$', 'N8GAFFPlayerSD$')
		,('AFF_BalPlayerTB', 'N8GAFFPlayerTB')
		,('AFF_BalPlayerUS$', 'N8GAFFPlayerUS$')
		,('AFF_BalPlayerUUS', 'N8GAFFPlayerUUS')
		,('AFF_BalPlayerWON', 'N8GAFFPlayerWON')
		,('AFF_BalWireUS$', 'N8GAFFMBankUS$')
		,('AFF_BalWireUUS', 'N8GAFFMBankUUS')
		,('AFF_BaseCurrencies', '51:VND,3:USD')
		,('AFF_CheckData_Bettrans', '2020-10-01')
		,('AFF_CommissionDate', '2020-09-30')
		,('AFF_SupportedCurrencies', '51:VND')
		,('AffCurrency', '51')
		,('BrandName', 'Goal123')
		,('LastImportedTime_ExchangeOanda', '2020-10-01')
		,('LaunchDate', '2020-10-01')
		,('MaxSubLevel', '4')
		,('MemberInfoLastImportedTime', '2020-10-01')
		,('Payment_Method', 'Player:Goal123 Player Account,Moneybookers:Moneybookers,Wire:Wire Transfer')
		,('Payment_MinAmount', '2300')
		,('SiteName', 'N8G')
		,('SoftLaunchDate', '2020-10-01')
		,('TimeZone', '8')
END