USE Affiliate_N88
GO

INSERT INTO dbo.Deductions (DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted)
SELECT 10, 'Platform Fee', 0.17, 0, 0
UNION ALL SELECT 11, 'Operational Fee', 0.07, 0, 0
UNION ALL SELECT 12, 'Banking Fee', 0.02, 0, 0
UNION ALL SELECT 13, 'Exchange Win Loss Share', 0, 0, 0
UNION ALL SELECT 14, 'Exchange Commission Share', 0, 0, 0
GO

SET IDENTITY_INSERT dbo.CommGroup ON
INSERT INTO dbo.CommGroup (GroupID, GroupName, Creator, IsDeleted, Description)
SELECT 1, 'Default', 8, 0, 'Default System Commission Group'
UNION ALL SELECT 2, 'NoCommission', 35915769, 0, 'Group for all zero commission/closed affiliates'
SET IDENTITY_INSERT dbo.CommGroup OFF
GO

INSERT INTO dbo.AffType (TypeId, Name, Description, Creator, IsShown)
SELECT 1, 'Asian', 'Asian Affiliate', 35915769, 1
GO

INSERT INTO dbo.LandingPage(PageName, PageCode, IsDeleted)
SELECT 'Home', 'home', 0
UNION ALL SELECT 'Signup', 'signup', 0
GO

INSERT INTO dbo.TierSetting (GroupId, TierId, MinAmount, MaxAmount, MinAM, MaxAM, Commission)
SELECT 1, 1, 0, 10, 0, 1, 0.15
UNION ALL SELECT 1, 2, 11, 100000000000000, 2, 1000000000, 0.3
UNION ALL SELECT 2, 1, 0, 100000000000000, 0, 1000000000, 0
GO

INSERT INTO dbo.TierSettingHistory(GroupId, MonthDate, TierId, MinAmount, MaxAmount, MinAM, MaxAM, Commission)
SELECT 1, '2020-05-31', 1, 0, 10, 0, 1, 0.15
UNION ALL SELECT 1, '2020-05-31', 2, 11, 100000000000000, 2, 1000000000, 0.3
UNION ALL SELECT 2, '2020-05-31', 1, 0, 100000000000000, 0, 1000000000, 0
GO

INSERT INTO dbo.DeductionSetting (GroupId,DeductionId,DeductedPercentage,NextDeductedPercentage,ProductId,GroupProductId,NextGroupProductId)
SELECT c.GroupID, 10, 0.17, 0.17, p.ProductId, 1, 1
FROM dbo.Products p
	CROSS JOIN dbo.CommGroup c
UNION ALL
SELECT c.GroupID, 11, 0.07, 0.07, 0, 1, 1
FROM dbo.CommGroup c
UNION ALL
SELECT c.GroupID, 12, 0.02, 0.02, 0, 1, 1
FROM dbo.CommGroup c
UNION ALL
SELECT c.GroupID, 13, 0, 0, 31, 1, 1
FROM dbo.CommGroup c
UNION ALL
SELECT c.GroupID, 14, 0, 0, 31, 1, 1
FROM dbo.CommGroup c

INSERT INTO dbo.DeductionSettingHistory (GroupID, MonthDate, DeductionID, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupID, '2020-05-31', DeductionID, DeductedPercentage, ProductId, GroupProductId FROM dbo.DeductionSetting WITH (NOLOCK)
GO

INSERT INTO dbo.Products (ProductId, ProductName, ProductPrefix, IsIBC, Enabled, IsTest, ReleasedDate, RefProductId, DataSource)
SELECT ProductId, ProductName, ProductPrefix, IsIBC, Enabled, IsTest, ReleasedDate, RefProductId, DataSource
FROM Affiliate_N8G.dbo.Products WITH (NOLOCK)
GO

DECLARE @currentDate DATETIME
SET @currentDate = CURRENT_TIMESTAMP

INSERT INTO dbo.Affiliate_User (CreateDate, Creator, GroupId, Closed, LoginCount, IPLogin, LastLogged, On_SessionId, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName)
SELECT @currentDate, 35915769, 1, Closed, LoginCount, IPLogin, LastLogged, On_SessionId, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName
FROM Affiliate_N8G.dbo.Affiliate_User WITH (NOLOCK)

INSERT INTO dbo.AffGroupInfo (GroupName, GroupDesc, CreateDate, ModifyDate, DisplayOrder, Creator)
SELECT GroupName, GroupDesc, @currentDate, @currentDate, DisplayOrder, 35915769
FROM Affiliate_N8G.dbo.AffGroupInfo WITH (NOLOCK)
WHERE GroupName IN ('None', 'IT')

INSERT INTO dbo.AffFunctionInfo (FuncName,FuncNote,FuncDesc,FuncRender,CreateDate,ModifyDate,DisplayOrder,Creator,FileNames)
SELECT FuncName,FuncNote,FuncDesc,FuncRender,@currentDate,@currentDate,DisplayOrder,35915769,FileNames
FROM Affiliate_N8G.dbo.AffFunctionInfo WITH (NOLOCK)

INSERT INTO dbo.AffMemberPolicy (CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT u.CustId, f.FuncId, 3, @currentDate, @currentDate, 35915769
FROM dbo.Affiliate_User u WITH (NOLOCK)
	CROSS JOIN dbo.AffFunctionInfo f WITH (NOLOCK)

INSERT INTO dbo.AffGroupPolicy (GroupId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT g.GroupId, f.FuncId, 3, @currentDate, @currentDate, 35915769
FROM dbo.AffGroupInfo g WITH (NOLOCK)
	CROSS JOIN dbo.AffFunctionInfo f WITH (NOLOCK)
GO

INSERT INTO dbo.SystemSettings (SName, SValue)
SELECT SName, REPLACE(SValue, 'N8GAFF', 'N88AFF')
FROM Affiliate_N8G.dbo.SystemSettings WITH (NOLOCK)
GO

UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = CASE SName
				WHEN 'BrandName' THEN 'Nova88'
				WHEN 'SoftLaunchDate' THEN '2020-05-01'
				WHEN 'SiteName' THEN 'N88'
				ELSE SValue END
WHERE SName IN ('BrandName', 'SoftLaunchDate', 'SiteName')
GO

UPDATE dbo.SystemSettings
SET SValue = '3:USD,2:MYR,6:EUR,12:GBP,13:CNY,15:IDR,32:JPY,45:KRW,4:THB,20:UUS'
WHERE SName = 'AFF_SupportedCurrencies'
GO

UPDATE dbo.SystemSettings
SET SValue = '3:USD,13:CNY,6:EUR,2:MYR'
WHERE SName = 'AFF_BaseCurrencies'
GO

UPDATE dbo.SystemSettings
SET SValue = '3'
WHERE SName = 'AffCurrency'
GO

UPDATE dbo.SystemSettings
SET SValue = 'Player:Nova88 Player Account'
WHERE SName = 'Payment_Method'
GO

INSERT INTO dbo.Market (MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName)
SELECT MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName
FROM Affiliate_N8G.dbo.Market WITH (NOLOCK)
GO

INSERT INTO dbo.Messages (MessageId,MessageTypeId,Description,MessageContentEN,MessageContentCS,MessageContentCH,MessageContentID,MessageContentVN,MessageContentTH,MessageContentKO,MessageContentES,MessageContentJP,MessageContentHIEN,MessageContentENEURO)
SELECT MessageId,MessageTypeId,Description,MessageContentEN,MessageContentCS,MessageContentCH,MessageContentID,MessageContentVN,MessageContentTH,MessageContentKO,MessageContentES,MessageContentJP,MessageContentHIEN,MessageContentENEURO
FROM Affiliate_N8G.dbo.Messages WITH (NOLOCK)
GO

INSERT INTO dbo.IPv4Addresses ([From], [To], Code2, Code3, Country)
SELECT [From], [To], Code2, Code3, Country
FROM Affiliate_N8G.dbo.IPv4Addresses WITH (NOLOCK)
GO

INSERT INTO dbo.TransType (TypeId, TypeName, TypeDesc)
SELECT TypeId, TypeName, TypeDesc
FROM Affiliate_N8G.dbo.TransType WITH (NOLOCK)
GO

INSERT INTO dbo.LogType (TypeId, TypeName, Description)
SELECT TypeId, TypeName, Description
FROM Affiliate_N8G.dbo.LogType WITH (NOLOCK)
GO

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName)
SELECT ActionId, ActionTypeId, SPName
FROM Affiliate_N8G.dbo.LogAction WITH (NOLOCK)
GO