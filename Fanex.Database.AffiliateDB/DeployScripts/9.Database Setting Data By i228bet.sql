-- This script should be prepare for each Licensee
use [Affiliate_i228bet]

GO
-- Update MultipliedBy column
update Currency
set multipliedBy=(case when currencycode='IDR' then 1000
                       when currencycode='VND' then 1000
				       else 1	    
				  end)
				  	    
--  Replace currency in affiliate content
Update refresources set resourcevalue = replace(resourcevalue,'CNY','CNY')
WHERE refid='affiliatecontent' and resourcevalue like '%CNY%'

Update refresources set resourcevalue = replace(resourcevalue,'mymbet','i228bet')
WHERE resourcevalue like '%mymbet%'


-- Set up AffType
truncate table AffType

INSERT INTO [dbo].[AffType]
           ([Name]
           ,[Description]
           ,[CreatedDate]
           ,[Creator])

select 'Normal','Normal Affiliate',getdate(),3


---- Set up Language table
truncate table Language

INSERT INTO [dbo].[Language]
           ([LanguageID]
           ,[LanguageName]
           ,[CountryID]
           ,[Creator]
           ,[CreatedDate]
           ,[Order])

select 'id-ID',N'Indonesia','ID',3,getdate(),4
union all
select 'en-US',N'English','GB',3,getdate(),3
union all
select 'zh-CN',N'中文简体','CN',3,getdate(),2
union all
select 'zh-TW',N'中文繁体','TW',3,getdate(),1
union all
select 'th-TH',N'ภาษาไทย','TH',3,getdate(),5


-- Set up Product table
truncate table Product
INSERT INTO [dbo].[Product]
           ([ProductID]
           ,[ProductName]
           ,[API_ProductID]
           ,[Creator]
           ,[CreatedDate]
           ,[Description]
           ,[BettypeList]
           ,[QMTurnOver]
           ,[QMDeposit]
           ,[ReportColumns])
select 1,'Sportsbook',0,3,GetDate(),'Sportsbook product','',100,100,''
union all
select 2,'RNG Casino',251,3,GetDate(),'RNG Casino','',100,100,''
union all
select 3,'Number Game',161,3,GetDate(),'Number Game','',100,100,''
union all
select 4,'Live Casino',162,3,GetDate(),'Live Casino','',100,100,''

-- set up Domain table
truncate table AffDomain
INSERT INTO [dbo].[AffDomain]
           ([DomainName]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator])
select 'go.i228bet.com',getdate(),getdate(),3

truncate table MemberDomain
INSERT INTO [dbo].[MemberDomain]
           ([DomainName]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator])
select 'sbtest.i228bet.com:38865/vender.aspx',getdate(),getdate(),3
union all
select 'www.i228bet.com/vender.aspx',getdate(),getdate(),3

truncate table [AffDomainControl]
INSERT INTO [dbo].[AffDomainControl]
           ([AffDomainID]
           ,[MemberDomainID]
           ,[CountryID]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator]
           ,[Status])

select 1,1,'-',getdate(),getdate(),3,1
union all
select 1,2,'-',getdate(),getdate(),3,1

-- Set up CurrencyConverter -- --  All currencies
truncate table [dbo].[CurrencyConverter]
INSERT INTO [dbo].[CurrencyConverter]
           ([ApplicationID]
           ,[PartnerCurrency]
           ,[ExchangeID]
           ,[CreatedDate]
           ,[PartnerExchangeID])


select 1,'RMB',22,getdate(),13
union all
select 1,'UUS',9999,getdate(),20
union all
select 1,'AUD',5,getdate(),9
union all
select 1,'EUR',34,getdate(),6
union all
select 1,'IDR',47,getdate(),15
union all
select 1,'THB',102,getdate(),43
union all
select 1,'USD',109,getdate(),3
union all
select 1,'MYR',64,getdate(),2


/* select * from Currency where CurrencyCode='USD' --[ExchangeID]
 select * from bodb02.dbo.Exchange where Currency='UUS' --[PartnerExchangeID]
 */



-- Set up Member Currencies & Affiliate currencies & admin currencies
truncate table [dbo].[Exchange]
truncate table [dbo].[ExchangeDaily]

INSERT INTO [dbo].[Exchange]
           ([ExchangeID]
           ,[Code]
           ,[Currency]
           ,[Creator]
           ,[CreatedDate]
           ,[IsAutoRefresh]
           ,[Prefix]
           ,[DepositPercent]
           ,[WithdrawalPercent]
           ,[USD]
           ,[USD_Market]
           ,[EUR]
           ,[EUR_Market]
           ,[CNY]
           ,[CNY_Market]
           ,[UUS]
           ,[UUS_Market]
           ,[MYR]
           ,[MYR_Market]
           ,[SGD]
           ,[SGD_Market]
           ,[IDR]
           ,[IDR_Market]
           ,[AUD]
           ,[AUD_Market]
           ,[CHF]
           ,[CHF_Market]
           ,[GBP]
           ,[GBP_Market]
           ,[THB]
           ,[THB_Market]
           ,[VND]
           ,[VND_Market])

		   
select 22,'CNY','China Yuan Renminbi',3,getdate(),1,'¥',0.03,0.03,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
union all
select 9999,'UUS','Virtual US$',3,getdate(),1,'$',0.03,0.03,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
union all
select 5,'AUD','Australia Dollar',3,getdate(),1,'$',0.03,0.03,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
union all
select 34,'EUR','Euro Member Countries',3,getdate(),1,'€',0.03,0.03,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
union all
select 47,'IDR','Indonesia Rupiah',3,getdate(),1,'Rp',0.03,0.03,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
union all
select 102,'THB',' Thailand Baht',3,getdate(),1,'฿',0.03,0.03,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
union all
select 109,'USD','United States Dollar',3,getdate(),1,'$',0.03,0.03,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
union all
select 64,'MYR','Malaysia Ringgit',3,getdate(),1,'RM',0.03,0.03,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0




-- set up System Settings
truncate table [SystemSettings]


/****** Object:  Table [dbo].[SystemSettings]    Script Date: 05/23/2013 05:33:27 ******/
--SET IDENTITY_INSERT [dbo].[SystemSettings] ON
-- setting languages for affiliate and affiliate Admin Sites
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_AdminSupportedLanguages', N'en-US,zh-TW,zh-CN', N'List of supported Affiliate''s Admin languages', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_AffiliateSupportedLanguages', N'n-US,zh-CN,zh-TW', N'List of supported Affiliate''s Admin languages', NULL)


--Banner Directory Folder
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDirectory', N'E:/1.Web/3.i228bet/3.Banner/Content/Banners/', NULL, N'UAT')
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDirectory', N'E:/1.Web/3.i228bet/3.Banner/Content/Banners/', NULL, N'Production')

-- Banner URL
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDomain', N'http://banner.i228bet.com/Content/Banners/', NULL, N'UAT')
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDomain', N'http://banner.i228bet.com/Content/Banners/', NULL, N'Production')

--Banner Script URL
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerScriptUrl', N'http://banner.i228bet.com/MarketingTools/GetScript/', NULL, N'Production')
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerScriptUrl', N'http://banner.i228bet.com/MarketingTools/GetScript/', NULL, N'UAT')

-- Minimum Withdrawal for affiliate by AffiliateCurrencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MinPlayerCNY', N'100', NULL, NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MinPlayerUSD', N'100', NULL, NULL)
INSERT [dbo].[SystemSettings] ([Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MinPlayerUUS', N'100', NULL, NULL)

-- Balance Account for Withdrawal by Player Currencies

INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_BalPlayerUUS', N'i228betAFFPlayerUUS', NULL, NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_BalPlayerCNY', N'i228betAFFPlayerRMB', NULL, NULL)

-- System Name
INSERT [dbo].[SystemSettings] ([Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemName', N'i228bet', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemNameForMail', N'i228bet', N'use System Name to send Mail', NULL)
--select * from licensees where licenseename='i228bet'
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'LicenseeID', N'60', N'LicenseeID i228bet from DB054.bodb_Licensee.dbo.Licensees', NULL)

-- Afiliate System Base Currencies = Affiliate Admin Currency + Affiliate base currencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_SupportedCurrencies', N'CNY,UUS', N'', NULL)

-- Member's Currencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_PlayerCurrencies', N'CNY,UUS', N'', NULL)


-- System Currency for admin site
INSERT [dbo].[SystemSettings] ([Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemCurrency', N'CNY', N'', NULL)

-- Affiliate's Currencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AffiliateCurrencies', N'CNY,USD', N'List of supported Affiliate''s currencies', NULL)

-- All base currencies for affiliate system = all currencies of every licensee, nochange
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SupportedBaseCurrencies', N'MYR,CNY,EUR,USD,UUS,SGD,AUD,IDR,CHF,GBP,THB,VND', N'All base currencies for the system', NULL)

-- System start date
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemStartDate', N'2013-05-01', N'System start date', NULL)


/****** Object:  Table [dbo].[CommGroup]    Script Date: 05/23/2013 07:26:14 ******/
truncate table [dbo].[CommGroup]
INSERT [dbo].[CommGroup] ([GroupID], [GroupName], [CreatedDate], [Creator], [IsDeleted], [Description], [QualifiedAmount], [Currency]) VALUES (101, N'Normal', CAST(0x0000A1930180A31E AS DateTime), 3, 0, N'', 100.0000, 22)
INSERT [dbo].[CommGroup] ([GroupID], [GroupName], [CreatedDate], [Creator], [IsDeleted], [Description], [QualifiedAmount], [Currency]) VALUES (102, N'NoCommission', CAST(0x0000A19301835A63 AS DateTime), 3, 0, N'', 100.0000, 22)

/****** Object:  Table [dbo].[GroupSetting]    Script Date: 05/23/2013 07:39:21 ******/
truncate table [dbo].[GroupSetting]
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 1, 1, 0.0000, 5.0000, 0, 5, CAST(0.00000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 1, 2, 6.0000, 18599.0000, 6, 10, CAST(0.20000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 1, 3, 18600, 270000.0000, 11, 50, CAST(0.30000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 1, 4, 270001.0000, 100000000000000.0000, 51, 1000000000, CAST(0.40000000 AS Decimal(9, 8)))

INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 2, 1, 0.0000, 5.0000, 0, 5, CAST(0.00000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 2, 2, 6.0000, 18599.0000, 6, 10, CAST(0.20000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 2, 3, 18600, 270000.0000, 11, 50, CAST(0.30000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 2, 4, 270001.0000, 100000000000000.0000, 51, 1000000000, CAST(0.40000000 AS Decimal(9, 8)))

INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 3, 1, 0.0000, 5.0000, 0, 5, CAST(0.00000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 3, 2, 6.0000, 19849.0000, 6, 10, CAST(0.20000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 3, 3, 19850, 198459.0000, 11, 25, CAST(0.25000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 3, 4, 198460, 496149.0000, 26, 50, CAST(0.30000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (101, 3, 5, 496150.0000, 100000000000000.0000, 51, 1000000000, CAST(0.35000000 AS Decimal(9, 8)))

INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (102, 1, 1, 0, 100000000000000.0000, 0, 1000000000, CAST(0.00000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (102, 2, 1, 0, 100000000000000.0000, 0, 1000000000, CAST(0.00000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (102, 3, 1, 0, 100000000000000.0000, 0, 1000000000, CAST(0.00000000 AS Decimal(9, 8)))
INSERT [dbo].[GroupSetting] ([GroupID], [ProductID], [TierID], [MinAmount], [MaxAmount], [MinQM], [MaxQM], [Commission]) VALUES (102, 4, 1, 0, 100000000000000.0000, 0, 1000000000, CAST(0.00000000 AS Decimal(9, 8)))

-- Finish



--customer page
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'CustomerPage', N'reg', N'SignUp', N'support query string act=reg will be redirected to Sign Up page', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'CustomerPage', N'sports', N'Sportsbook', N'support query string act=sports will be redirected to sports page', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'CustomerPage', N'ng', N'NumberGame', N'support query string act=ng will be redirected to Number Game page ', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'CustomerPage', N'lc', N'LiveCasino', N'support query string act=lc will be redirected to Live Casino page ', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'CustomerPage', N'Home', N'Home', N'Redirect to home page', NULL)

--language mapping with member site setting
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'en', N'en-US', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'eneuro', N'en-US', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'ct', N'zh-TW', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'cs', N'zh-CN', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'th', N'th-TH', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'es', N'es-ES', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'vn', N'vi-VN', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangCodeShort', N'id', N'id-ID', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangMapping', N'en-US', N'en', N'Mapping from affiliate site''s language to member site''s language', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangMapping', N'zh-CN', N'cs', N'Mapping from affiliate site''s language to member site''s language ', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangMapping', N'id-ID', N'id', N'Mapping from affiliate site''s language to member site''s language ', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangMapping', N'zh-TW', N'ch', N'Mapping from affiliate site''s language to member site''s language ', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'LangMapping', N'th-TH', N'th', N'Mapping from affiliate site''s language to member site''s language ', NULL)




INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_OldReportDateDaily', N'', N'', NULL)

INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'value', N'EuropeanCurrencies', N'EUR', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'value', N'EuropeanDepositChargePercent', N'0', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'value', N'EuropeanWithdrawalChargePercent', N'0', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'value', N'AsianDepositChargePercent', N'0', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'value', N'AsianWithdrawalChargePercent', N'0', N'', NULL)

INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'value', N'ConfigurationTypeList', N'Meta,Value,ResourceRefID,CustomerPage,LangCodeShort,LangMapping', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES (N'ResourceRefID', N'AffiliateContent', N'Affiliate Content', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'ResourceRefID', N'EmailTemplate', N'Email Template', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'ResourceRefID', N'Resource', N'Resource', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'ExcelConfiguration', N'ExcelWidth', N'100', N'Width of column', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'RedirectPage', N'casino', N'casino', N'Redirect To casino Page', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'RedirectPage', N'promotion', N'promotion', N'Redirect To promotion Page', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'RedirectPage', N'signup', N'signup', N'Redirect To signup Page', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'RedirectPage', N'sportsbook', N'sportsbook', N'Redirect To sportsbook Page', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'ResourceRefID', N'Product', N'Product', N'Product', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'ResourceRefID', N'BannerTypes', N'BannerTypes', N'BannerTypes', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'ResourceRefID', N'Country', N'Country', N'Country', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'ResourceRefID', N'News', N'News', N'News', NULL)

-- SET IDENTITY_INSERT [dbo].[SystemSettings] OFF


/****** Object:  Table [dbo].[DeductionSetting]    Script Date: 05/23/2013 07:39:21 ******/


-- set up Banner Types
/****** Object:  Table [dbo].[BannerTypes]    Script Date: 05/23/2013 07:26:14 ******/
SET IDENTITY_INSERT [dbo].[BannerTypes] ON
truncate table [dbo].[BannerTypes]
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (1, N'ImageType', N'Image', 2, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (2, N'ImageType', N'Flash', 1, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (3, N'TextCategory', N'Basketball', 1, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (4, N'TextCategory', N'Bonus', 2, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (5, N'TextCategory', N'Casino', 3, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (6, N'TextCategory', N'Football', 4, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (7, N'TextCategory', N'Poker', 5, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (8, N'TextCategory', N'Tennis', 6, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (9, N'MediaCategory', N'Casino', 1, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (10, N'MediaCategory', N'Number Game', 2, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (11, N'MediaCategory', N'Racebook', 3, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (12, N'MediaCategory', N'Sportsbook', 4, NULL)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (13, N'MediaSubCategory', N'Baccarat', 1, 9)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (14, N'MediaSubCategory', N'Blackjack', 2, 9)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (15, N'MediaSubCategory', N'Casino Bonus', 3, 9)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (16, N'MediaSubCategory', N'Roulette', 4, 9)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (17, N'MediaSubCategory', N'Sic bo', 5, 9)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (18, N'MediaSubCategory', N'Slot', 6, 9)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (19, N'MediaSubCategory', N'Basketball', 1, 12)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (20, N'MediaSubCategory', N'SB Bonus', 2, 12)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (21, N'MediaSubCategory', N'Soccer', 3, 12)
INSERT [dbo].[BannerTypes] ([TypeID], [Type], [Value], [DisplayOrder], [ParentID]) VALUES (22, N'MediaSubCategory', N'Tennis', 4, 12)

SET IDENTITY_INSERT [dbo].[BannerTypes] OFF

-- delete redundant data

truncate table news;

delete RefResources where RefID='News';

--Update email contact in DB. Should update EmailContact in web.config
update RefResources
set ResourceValue = REPLACE(ResourceValue, 'i228bet@i228bet.com', 'EmailContact@yahoo.com')
where ResourceValue like '%i228bet@i228bet.com%'