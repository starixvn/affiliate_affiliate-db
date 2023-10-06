-- This script should be prepare for each Licensee
use [Affiliate_Licensee]

GO
-- Update MultipliedBy column
update Currency
set multipliedBy=(case when currencycode='IDR' then 1000
                       when currencycode='VND' then 1000
				       else 1	    
				  end)
				  	    

Update refresources set resourcevalue = replace(resourcevalue,'mymbet','Athena000')
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
select 'go.athena000.com',getdate(),getdate(),3

truncate table MemberDomain
INSERT INTO [dbo].[MemberDomain]
           ([DomainName]
           ,[CreateDate]
           ,[ModifyDate]
           ,[Creator])
select 'www.athena000.com/vender.aspx',getdate(),getdate(),3


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

-- Set up CurrencyConverter -- --  All currencies

/* select * from Currency where CurrencyCode='USD' --[ExchangeID]
 select * from bodb02.dbo.Exchange where Currency='UUS' --[PartnerExchangeID]
 */

truncate table [dbo].[CurrencyConverter]


/****** Object:  Table [dbo].[CurrencyConverter]    Script Date: 07/10/2013 22:08:39 ******/

INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'AUD', 5, CAST(0x0000A1F50167FEB0 AS DateTime), 9)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'CHF', 98, CAST(0x0000A1F7016D23C8 AS DateTime), 41)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'EUR', 34, CAST(0x0000A1F50167FEB0 AS DateTime), 6)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'GBP', 108, CAST(0x0000A1F7016F0260 AS DateTime), 12)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'IDR', 47, CAST(0x0000A1F50167FEB0 AS DateTime), 15)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'MYR', 64, CAST(0x0000A1F50167FEB0 AS DateTime), 2)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'CNY', 22, CAST(0x0000A1F50167FEB0 AS DateTime), 13)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'SGD', 91, CAST(0x0000A1F7016D23C8 AS DateTime), 1)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'THB', 102, CAST(0x0000A1F50167FEB0 AS DateTime), 4)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'USD', 109, CAST(0x0000A1F50167FEB0 AS DateTime), 3)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'UUS', 9999, CAST(0x0000A1F50167FEB0 AS DateTime), 20)
INSERT [dbo].[CurrencyConverter] ([ApplicationID], [PartnerCurrency], [ExchangeID], [CreatedDate], [PartnerExchangeID]) VALUES (1, N'VND', 113, CAST(0x0000A1F7016D23C8 AS DateTime), 51)



-- Set up Member Currencies & Affiliate currencies & admin currencies
truncate table [dbo].[Exchange]
truncate table [dbo].[ExchangeDaily]

/****** Object:  Table [dbo].[Exchange]    Script Date: 07/10/2013 22:08:39 ******/
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (22, N'CNY', N'China Yuan Renminbi', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'¥', 0.03, 0.03, 0.1619, 0.1619, 0.126, 0.126, 1, 1, 0, 0, 0.5173, 0.5173, 0.207, 0.207, 1617.04, 1617.04, 0.1769, 0.1769, 0.1567, 0.1567, 0.1086, 0.1086, 5.0769, 5.0769, 3441.27, 3441.27)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (9999, N'UUS', N'Virtual US$', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'$', 0.03, 0.03, 2.7, 0, 5, 0, 0, 0, 1, 1, 0, 0, 3.8, 0, 0, 0, 4.3, 0, 0, 0, 0, 0, 0, 0, 0, 0)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (5, N'AUD', N'Australia Dollar', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'$', 0.03, 0.03, 0.9154, 0.9154, 0.7128, 0.7128, 5.6597, 5.6597, 0, 0, 2.9252, 2.9252, 1.1706, 1.1706, 9144.46, 9144.46, 1, 1, 0.886, 0.886, 0.6143, 0.6143, 28.7102, 28.7102, 19460.6, 19460.6)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (34, N'EUR', N'Euro Member Countries', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'€', 0.03, 0.03, 1.2843, 1.2843, 1, 1, 7.9409, 7.9409, 0, 0, 4.1041, 4.1041, 1.6425, 1.6425, 12830.2, 12830.2, 1.4033, 1.4033, 1.243, 1.243, 0.8619, 0.8619, 40.282, 40.282, 27304.2, 27304.2)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (47, N'IDR', N'Indonesia Rupiah', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'Rp', 0.03, 0.03, 0.1007, 0.1007, 0.07842, 0.07842, 0.6226, 0.6226, 0, 0, 0.3218, 0.3218, 0.1288, 0.1288, 1, 1, 0.11, 0.11, 0.09747, 0.09747, 0.06758, 0.06758, 3.158, 3.158, 2140.9, 2140.9)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (102, N'THB', N' Thailand Baht', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'฿', 0.03, 0.03, 0.03196, 0.03196, 0.02489, 0.02489, 0.1976, 0.1976, 0, 0, 0.1021, 0.1021, 0.04088, 0.04088, 319.327, 319.327, 0.03493, 0.03493, 0.03094, 0.03094, 0.02145, 0.02145, 1, 1, 679.568, 679.568)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (109, N'USD', N'United States Dollar', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'$', 0.03, 0.03, 1, 1, 0.7787, 0.7787, 6.183, 6.183, 0, 0, 3.1956, 3.1956, 1.2789, 1.2789, 9990.01, 9990.01, 1.0927, 1.0927, 0.9679, 0.9679, 0.6711, 0.6711, 31.3649, 31.3649, 21260, 21260)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (64, N'MYR', N'Malaysia Ringgit', 3, CAST(0x0000A1F50167FEB4 AS DateTime), 1, N'RM', 0.03, 0.03, 0.3136, 0.3136, 0.2442, 0.2442, 1.9388, 1.9388, 0, 0, 1, 1, 0.401, 0.401, 3132.5, 3132.5, 0.3426, 0.3426, 0.3035, 0.3035, 0.2104, 0.2104, 9.8349, 9.8349, 6666.35, 6666.35)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (108, N'GBP', N'United Kingdom Pound', 3, CAST(0x0000A1F700624334 AS DateTime), 1, N'£', 0.03, 0.03, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (91, N'SGD', N'Singapore Dollar', 3, CAST(0x0000A1F70063D61C AS DateTime), 1, N'$', 0.03, 0.03, 0.7822, 0.7822, 0.6091, 0.6091, 4.8366, 4.8366, 0, 0, 2.4997, 2.4997, 1, 1, 7814.52, 7814.52, 0.8547, 0.8547, 0.7571, 0.7571, 0.525, 0.525, 24.5347, 24.5347, 16630.3, 16630.3)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (98, N'CHF', N'Switzerland Franc', 3, CAST(0x0000A1F70063D61C AS DateTime), 1, N'CHF', 0.03, 0.03, 1.0334, 1.0334, 0.8047, 0.8047, 6.3895, 6.3895, 0, 0, 3.3024, 3.3024, 1.3216, 1.3216, 10323.7, 10323.7, 1.1292, 1.1292, 1, 1, 0.6935, 0.6935, 32.4125, 32.4125, 21970.1, 21970.1)
INSERT [dbo].[Exchange] ([ExchangeID], [Code], [Currency], [Creator], [CreatedDate], [IsAutoRefresh], [Prefix], [DepositPercent], [WithdrawalPercent], [USD], [USD_Market], [EUR], [EUR_Market], [CNY], [CNY_Market], [UUS], [UUS_Market], [MYR], [MYR_Market], [SGD], [SGD_Market], [IDR], [IDR_Market], [AUD], [AUD_Market], [CHF], [CHF_Market], [GBP], [GBP_Market], [THB], [THB_Market], [VND], [VND_Market]) VALUES (113, N'VND', N'Viet Nam Dong', 3, CAST(0x0000A1F70063D61C AS DateTime), 1, N'd', 0.03, 0.03, 0.04713, 0.04713, 0.0367, 0.0367, 0.2914, 0.2914, 0, 0, 0.1506, 0.1506, 0.06027, 0.06027, 470.8, 470.8, 0.05149, 0.05149, 0.04561, 0.04561, 0.03163, 0.03163, 1.478, 1.478, 1, 1)



-- set up System Settings
truncate table [SystemSettings]


/****** Object:  Table [dbo].[SystemSettings]    Script Date: 05/23/2013 05:33:27 ******/
--SET IDENTITY_INSERT [dbo].[SystemSettings] ON
-- setting languages for affiliate and affiliate Admin Sites
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_AdminSupportedLanguages', N'en-US,zh-TW,zh-CN', N'List of supported Affiliate''s Admin languages', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_AffiliateSupportedLanguages', N'en-US,id-ID,zh-CN,zh-TW,th-TH', N'List of supported Affiliate''s Admin languages', NULL)

--setting for Adjustment limitation by currency

INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentUSD', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentIDR', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentCNY', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentEUR', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentVND', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentSGD', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentAUD', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentTHB', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentMYR', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentCHF', N'100000', N'Limit amount for adjustment', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MaximumAdjustmentGBP', N'100000', N'Limit amount for adjustment', NULL)




--Banner Directory Folder
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDirectory', N'E:/1.Web/1.Athena000/3.Banner/Content/Banners/', NULL, N'UAT')
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDirectory', N'E:/1.Web/1.Athena000/3.Banner/Content/Banners/', NULL, N'Production')

-- Banner URL
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDomain', N'http://banner.Athena000.com/Content/Banners/', NULL, N'UAT')
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerDomain', N'http://banner.Athena000.com/Content/Banners/', NULL, N'Production')

--Banner Script URL
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerScriptUrl', N'http://banner.Athena000.com/MarketingTools/GetScript/', NULL, N'Production')
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'BannerScriptUrl', N'http://banner.Athena000.com/MarketingTools/GetScript/', NULL, N'UAT')

-- Minimum Withdrawal for affiliate by AffiliateCurrencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MinPlayerCNY', N'100', NULL, NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MinPlayerUSD', N'100', NULL, NULL)
INSERT [dbo].[SystemSettings] ([Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_MinPlayerUUS', N'100', NULL, NULL)

-- Balance Account for Withdrawal by Player Currencies

INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_BalPlayerUUS', N'Athena000AFFPlayerUUS', NULL, NULL)


-- System Name
INSERT [dbo].[SystemSettings] ([Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemName', N'Athena000', N'', NULL)
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemNameForMail', N'Athena000', N'use System Name to send Mail', NULL)
--select * from licensees where licenseename='mymbet'
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'LicenseeID', N'26', N'LicenseeID mymbet from DB054.bodb_Licensee.dbo.Licensees', NULL)

-- Afiliate System Base Currencies = Affiliate Admin Currency + Affiliate base currencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_SupportedCurrencies', N'USD,IDR,CNY,EUR,VND,SGD,AUD,THB,MYR,CHF,GBP', N'', NULL)

-- Member's Currencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AFF_PlayerCurrencies', N'UUS', N'', NULL)


-- System Currency for admin site
INSERT [dbo].[SystemSettings] ([Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemCurrency', N'IDR', N'', NULL)

-- Affiliate's Currencies
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'AffiliateCurrencies', N'USD,IDR,CNY,EUR,VND,SGD,AUD,THB,MYR,CHF,GBP', N'List of supported Affiliate''s currencies', NULL)

-- All base currencies for affiliate system = all currencies of every licensee, nochange
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SupportedBaseCurrencies', N'MYR,CNY,EUR,USD,UUS,SGD,AUD,IDR,CHF,GBP,THB,VND', N'All base currencies for the system', NULL)

-- System start date
INSERT [dbo].[SystemSettings] ( [Type], [SName], [SValue], [Description], [Environment]) VALUES ( N'Meta', N'SystemStartDate', N'2013-05-01', N'System start date', NULL)


/****** Object:  Table [dbo].[CommGroup]    Script Date: 05/23/2013 07:26:14 ******/
truncate table [dbo].[CommGroup]
INSERT [dbo].[CommGroup] ([GroupID], [GroupName], [CreatedDate], [Creator], [IsDeleted], [Description], [QualifiedAmount], [Currency]) VALUES (101, N'Normal', CAST(0x0000A1930180A31E AS DateTime), 3, 0, N'', 100.0000, 109)
INSERT [dbo].[CommGroup] ([GroupID], [GroupName], [CreatedDate], [Creator], [IsDeleted], [Description], [QualifiedAmount], [Currency]) VALUES (102, N'NoCommission', CAST(0x0000A19301835A63 AS DateTime), 3, 0, N'', 100.0000, 109)

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
set ResourceValue = REPLACE(ResourceValue, 'mymbet@mymbet.com', 'Athena000.csd@gmail.com')
where ResourceValue like '%mymbet@mymbet.com%'
