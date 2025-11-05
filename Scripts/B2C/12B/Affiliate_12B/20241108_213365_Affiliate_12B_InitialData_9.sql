/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250213@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Initial data Affiliate_12B DB [RedmineID: #212201]
*/

USE Affiliate_12B
GO

-- TransType
INSERT INTO dbo.TransType (TypeId, TypeName, TypeDesc)
SELECT t.TypeId, t.TypeName, t.TypeDesc
FROM (
		VALUES (201, 'Monthly Earning', 'Affiliate Monthly Earning Transfer')
			,  (202, 'Payment', 		'Affiliate Payment')
			,  (203, 'Adjustment', 		'Affiliate Balance Adjustment')
			,  (204, 'Revenue Share', 	'Affiliate Monthly Revenue Share Transfer')
) AS t(TypeId, TypeName, TypeDesc)
	LEFT JOIN dbo.TransType tt WITH (NOLOCK) ON tt.TypeId = t.TypeId
WHERE tt.TypeId IS NULL
GO


-- Function Info
INSERT INTO dbo.AffFunctionInfo (FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
SELECT t.FuncName, t.FuncNote, t.FuncDesc, t.FuncRender, t.DisplayOrder, t.Creator, t.ParentId, t.FileNames
FROM (
	VALUES ('[UserControl]', '', 'User Control', 3, '1', 1000000000, NULL, 'UserControl/ListUser.aspx; UserControl/EditUser.aspx; UserControl/AddUser.aspx; UserControl/AddUserExist.aspx; UserControl/ListDepartment.aspx; UserControl/AddDepartment.aspx; UserControl/EditDepartment.aspx;UserControl/EditAdminPolicy.aspx; UserControl/EditGroupPolicy.aspx; UserControl/ListUserInDept.aspx; UserControl/UpdateMultiAdmins.aspx'),
		   ('[Affiliate]', '', 'Affiliate', 3, '1', 1000000000, NULL, 'UserInfo/AffiliateList.aspx; UserInfo/AffiliateUpd.aspx; UserInfo/AccOverview.aspx; UserInfo/MemberList.aspx; DailyEarning.aspx; DailyEarningDetail.aspx; EarningsHistory.aspx; MemberList.aspx; PlayersDetail.aspx; StatementUpd.aspx; Customer/AffDefault.aspx; Customer/Statistics.aspx; Customer/AffiliateInfo.aspx; UserInfo/MediaStatistics.aspx; UserInfo/note.aspx; Others/EmailHistory.aspx; Others/ViewEmailDetails.aspx;UserInfo/MemberListAll.aspx;GroupSetting/AssignGroup.aspx;UserInfo/MemberList.aspx;'),
		   ('[Payment]', '', 'Payment', 3, '1', 1000000000, NULL, 'Payment/PaymentRequest.aspx; Payment/PaymentUpdate.aspx; Payment/Payment_.aspx'),
		   ('[Media]', '', 'Media', 3, '1', 1000000000, NULL, 'Media/Listbanner.aspx; Media/AddBanner.aspx'),
		   ('[AffEx.Rate]', '', 'Affiliate Exchange', 3, '1', 1000000000, NULL, 'Exchange/AffRate.aspx; Exchange/AffEditRate.aspx'),
		   ('[HotNews]', '', 'HotNews', 3, '1', 1000000000, NULL, 'Others/Message.aspx'),
		   ('[RevenueGroup]', '', 'Revenue Group', 3, '1', 1000000000, NULL, 'GroupSetting/GroupSetting.aspx; GroupSetting/AddGroup.aspx; GroupSetting/EditGroup.aspx;'),
		   ('[AffReport]', '', 'Affiliate Report', 3, '1', 1000000000, NULL, 'Home/Home.aspx;Report/MemberReport.aspx;Report/AffiliateReport.aspx;Report/MemberStaticticsReport.aspx;Report/AffiliateQMReport.aspx;Report/Performance.aspx;Report/PerformanceReportByAffiliate.aspx'),
		   ('[Note]', NULL, 'Manage Notes', 3, '1', 1000000000, NULL, 'UserInfo/Note.aspx;'),
		   ('[SecurityQA]', NULL, 'Security Q&A', 3, '1', 1000000000, NULL, ''),
		   ('[Domain]', '', 'Domain Control', 3, '1', 1000000000, NULL, 'Domain/12BetDomain.aspx;Domain/Add12BetDomain.aspx;Domain/AddAffiliateDomain.aspx;Domain/AffiliateDomain.aspx;Domain/DomainControl.aspx;Domain/DomainControlIns.aspx;Domain/DomainControlUpd.aspx;Domain/Edit12BetDomain.aspx;Domain/EditAffiliateDomain.aspx;'),
		   ('[ActiveMembers]', '', 'Active Members', 3, '1', 1000000000, NULL, 'UserInfo/MemberActiveList.aspx'),
		   ('[MemberEmail]', '', 'Member''s Email', 3, '1', 1000000000, NULL, ''),
		   ('[TransferPlayerSetting]', '', 'Transfer Balance For Player Setting', 3, '7', 1000000000, NULL, NULL),
		   ('[TransferPlayerReport]', '', 'Transfer Balance For Player Report', 3, '7', 1000000000, NULL, NULL),
		   ('[EditAffiliateStatus]', '', 'Edit Affiliate Status', 3, '1', 1000000000, NULL, ''),
		   ('[EditAffiliateDetails]', '', 'Customer - Edit Affiliate Details', 3, '1', 1000000000, NULL, '')
) AS t(FuncName, FuncNote, FuncDesc, FuncRender, DisplayOrder, Creator, ParentId, FileNames)
	LEFT JOIN dbo.AffFunctionInfo ai WITH (NOLOCK) ON ai.FuncName = t.FuncName
WHERE ai.FuncName IS NULL
GO


-- Group Info
INSERT INTO dbo.AffGroupInfo (GroupName, GroupDesc, DisplayOrder, Creator)
SELECT t.GroupName, t.GroupDesc, t.DisplayOrder, t.Creator
FROM (
	VALUES ('None', 'None'   , 	'5', 1000000000)
		  ,('IT'  , 'IT dept', 	'5', 1000000000)
) AS t(GroupName, GroupDesc, DisplayOrder, Creator)
	LEFT JOIN dbo.AffGroupInfo ag WITH (NOLOCK) ON ag.GroupName = t.GroupName
WHERE ag.GroupName IS NULL
GO


-- Group Policy
INSERT INTO dbo.AffGroupPolicy (GroupId, FuncId, Policy, Creator)
SELECT t.GroupId, t.FuncId, 3 AS Policy, 1000000000 AS Creator
FROM (
	SELECT g.GroupId, f.FuncId
	FROM dbo.AffGroupInfo g WITH (NOLOCK)
		CROSS JOIN dbo.AffFunctionInfo f WITH (NOLOCK)
)t
	LEFT JOIN dbo.AffGroupPolicy ag WITH (NOLOCK) ON ag.GroupId = t.GroupId
												 AND ag.FuncId  = t.FuncId
WHERE ag.GroupId IS NULL OR ag.FuncId IS NULL
GO


-- Aff Member Login
INSERT INTO dbo.Affiliate_User (PageAccess, CreateDate, Creator, GroupId, Closed, LoginCount, IPLogin, LastLogged, On_SessionId, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName)
SELECT t.PageAccess, GETDATE() AS CreateDate, t.Creator, t.GroupId, t.Closed, t.LoginCount, t.IPLogin, GETDATE() AS LastLogged, t.On_SessionId, t.UserName, t.UserPwd, t.RoleId, '2026-01-01', t.FirstName, t.LastName
FROM (
	VALUES ( NULL, NULL, 1001, 0, 0, '175.41.181.209', 0, 'sa', '56E8A2D78170E87C928E480797CC73', 10, 'dba', ''),
		   ( NULL, 1000000000, 1001, 0, 0, '175.41.181.209', 0, 'AAStarixQC01', '56E8A2D78170E87C928E480797CC73', 6, '', ''),
		   ( NULL, 1000000000, 1001, 0, 0, '175.41.181.209', 0, 'AAStarixQC02', '56E8A2D78170E87C928E480797CC73', 6, '', '')
) AS t (PageAccess, Creator, GroupId, Closed, LoginCount, IPLogin, On_SessionId, UserName, UserPwd, RoleId, FirstName, LastName)
	LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON au.UserName = t.UserName
WHERE au.UserName IS NULL
GO


-- Aff Member Policy
INSERT INTO dbo.AffMemberPolicy (CustId, FuncId, Policy, Creator)
SELECT t.CustId, t.FuncId, 3 AS Policy, 1000000000 AS Creator
FROM (
	SELECT u.CustId, f.FuncId
	FROM dbo.Affiliate_User u WITH (NOLOCK)
		CROSS JOIN dbo.AffFunctionInfo f WITH (NOLOCK)
)t
	LEFT JOIN dbo.AffMemberPolicy am WITH (NOLOCK) ON am.CustId = t.CustId
												  AND am.FuncId = t.FuncId
WHERE am.CustId IS NULL OR am.FuncId IS NULL
GO


-- Settings info
INSERT INTO dbo.SystemSettings (SName, SValue)
SELECT t.SName, t.SValue
FROM (
	VALUES ('MaxSubLevel', '1000')
		  ,('Payment_MinAmount', '100')
		  ,('Payment_Method', 'Player:12Bet Player Account')
		  ,('AffCurrency', '3')
		  ,('AFF_CommissionDate', '2025-01-31') -- Note
		  ,('AFF_SupportedCurrencies', '2:MYR,3:USD,4:THB,13:CNY,15:IDR,45:KRW,51:VND,61:INR,74:BDT') -- Supported Currencies
		  ,('AFF_BaseCurrencies', '2:MYR,3:USD,4:THB,13:CNY,15:IDR,51:VND,61:INR,74:BDT') -- Base Currencies
		  ,('SoftLaunchDate', '2024-11-01')
		  ,('LaunchDate', '2024-11-01')
		  ,('AFF_PaymentCurrencies', '2:MYR,3:USD,4:THB,13:CNY,15:IDR,45:KRW,51:VND,61:INR,74:BDT') -- Note
		  ,('MemberInfoLastImportedTime', '2008-03-12 00:00:00') -- Note
		  ,('MemberInfoLastUpdatedTime', '2008-03-12 00:00:00') -- Note
		  ,('BrandName', '12Bet')
		  ,('SiteName', '12BET')
		  ,('TimeZone', '8')
		  ,('P2P_CutOffDate', '2021-07-01') -- The same N88
		  ,('LastImportedTime_ExchangeOanda', '2008-03-13')
		  ,('Report_CutOffDate', '2023-06-01') -- The same N88
) AS t(SName, SValue)
	LEFT JOIN dbo.SystemSettings ss WITH (NOLOCK) ON ss.SName = t.SName
WHERE ss.SName IS NULL
GO


-- Market info
INSERT INTO dbo.Market (MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName)
SELECT CASE m12.MarketId WHEN 'hi-IN' THEN 'en-IN'
						 WHEN 'hi'	  THEN 'hi-IN'
	   ELSE m12.MarketId END AS MarketId
	, m12.MarketName, m12.MarketNativeName, m12.ShortedCode, m12.DisplayName
FROM Affiliate_12BET.dbo.Market m12 WITH (NOLOCK)
	LEFT JOIN Market m WITH (NOLOCK) ON m12.MarketID = m.MarketId
WHERE m.MarketId IS NULL
GO


-- Aff Type info
INSERT INTO dbo.AffType (TypeId, Name, Description, Creator, IsShown)
SELECT t.TypeId, t.Name, t.Description, 1000000000 AS Creator, 1 AS IsShown
FROM (
	VALUES (2, N'Asian', N'Asian Affiliate')
		--,  (3, N'Media', N'Media Affiliate')
		--,  (4, N'European', N'European Affiliate')
)AS t(TypeId, Name, Description)
	LEFT JOIN dbo.AffType af WITH (NOLOCK) ON af.TypeId = t.TypeId
WHERE af.TypeId IS NULL
GO


-- Deductions info
INSERT INTO dbo.Deductions (DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted, DeductedAmount, IsDeductedPercent, Commission)
SELECT t.DeductionId, t.DeductionName, t.DeductedPercentage, t.IsTest, t.IsDeleted, t.DeductedAmount, t.IsDeductedPercent, t.Commission
FROM (
	VALUES (10, 'Platform Fee',		0.00000000, 0, 0, NULL, 1, 0.00000000)
		,  (11, 'Operational Fee', 	0.07000000, 0, 0, NULL, 1, 0.00000000)
		,  (13, 'Deposit Fee', 		0.02000000, 0, 0, NULL, 1, 0.00000000)
		,  (14, 'Withdrawal Fee', 	0.02000000, 0, 0, NULL, 1, 0.00000000)
		,  (15, 'P2P Fee', 			0.10000000, 0, 0, NULL, 1, 0.30000000)
		,  (16, 'Kill Rate', 		0.03000000, 0, 0, NULL, 1, 0.00000000)
) AS t(DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted, DeductedAmount, IsDeductedPercent, Commission)
	LEFT JOIN dbo.Deductions d WITH (NOLOCK) ON d.DeductionId = t.DeductionId
WHERE d.DeductionId IS NULL
GO


-- Group Type Info
INSERT INTO dbo.GroupType (GroupTypeBy, GroupTypeName, DisplayOrder)
SELECT t.GroupTypeBy, t.GroupTypeName, t.DisplayOrder
FROM (
	VALUES ('Winloss', 'Calculate Revenue Share by Winloss', 1)
	    --,  ('Turnover', 'Calculate Revenue Share by Turnover', 2)
) AS t(GroupTypeBy, GroupTypeName, DisplayOrder)
	LEFT JOIN dbo.GroupType gt WITH (NOLOCK) ON gt.GroupTypeBy = t.GroupTypeBy
WHERE gt.GroupTypeBy IS NULL
GO


-- AffiliateCode Info
BEGIN
	DECLARE @n INT = 10000, @batch INT = 5000, @msg VARCHAR(200) = ''
	WHILE @n < 99999
	BEGIN
		SELECT @msg = 'start insert from ' + CONVERT(VARCHAR(6), @n) + ' to ' + CONVERT(VARCHAR(6), @n + @batch - 1)
		;
		WITH cte_number AS(
			SELECT @n AS n
			UNION ALL
			SELECT n + 1
			FROM cte_number
			WHERE n < @n + @batch - 1
		)
		INSERT INTO dbo.AffiliateCode (AffCode)
		SELECT n
		FROM cte_number
		OPTION (MAXRECURSION 0)
	
		SELECT @n = @n + @batch
	
		RAISERROR (@msg, 0, 1) WITH NOWAIT
	
		WAITFOR DELAY '00:00:00.280'
	END
END
GO


-- Exchange: new currencies must be added
INSERT INTO dbo.Exchange (ExchangeId, Code, MultipliedBy)
SELECT t.ExchangeId, t.Code, t.MultipliedBy
FROM (
	VALUES (2,  'MYR', 1) 
		,  (3,  'USD', 1)
		,  (4,  'THB', 1)
		,  (13, 'CNY', 1)
		,  (15, 'IDR', 1000)
		,  (45, 'KRW', 1)
		,  (51, 'VND', 1000)
		,  (61, 'INR', 1)
		,  (97, 'BDT', 1)
) AS t(ExchangeId, Code, MultipliedBy)
	LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON e.ExchangeId = t.ExchangeId
WHERE e.ExchangeId IS NULL
GO


-- GroupComm info
INSERT INTO dbo.CommGroup (GroupName, Description, Creator, CreatedDate, IsPrivate, IsDeleted, SubCommRate)
SELECT t.GroupName, t.Description, 1000000000 AS Creator, GETDATE() AS CreatedDate, t.IsPrivate, t.IsDeleted, t.SubCommRate
FROM (
	VALUES ('Default Comm Group', 'Default group - All affiliates', 0, 0, 0.10000000) 
		 , ('NoCommission', 'Group for all zero commission/closed affiliates', 0, 0, 0.10000000)
)AS t (GroupName, Description, IsPrivate, IsDeleted, SubCommRate)
	LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.GroupName = t.GroupName
WHERE cg.GroupName IS NULL
GO


-- IP to Country
INSERT INTO dbo.IPv4Addresses ([From], [To], Code2, Code3, Country)
SELECT t.[From], t.[To], t.Code2, t.Code3, t.Country
FROM Affiliate_N88.dbo.IPv4Addresses t WITH (NOLOCK)
	LEFT JOIN dbo.IPv4Addresses e WITH (NOLOCK) ON t.[From] = e.[From] AND t.[To] = e.[To]
WHERE e.[From] IS NULL
GO


--- Message Error
INSERT INTO dbo.Messages (MessageId, MessageTypeId, Description, MessageContentBN, MessageContentENEURO, MessageContentEN, MessageContentHI, MessageContentHIEN, MessageContentID, MessageContentJP, MessageContentKH, MessageContentKO, MessageContentHITG, MessageContentTH, MessageContentVN, MessageContentCS, MessageContentCH)
SELECT m.MessageId, m.MessageTypeId, m.Description, m.MessageContentBN, m.MessageContentENEURO, m.MessageContentEN, m.MessageContentHIEN AS [MessageContentHI], m.MessageContentEN AS [MessageContentHIEN], m.MessageContentID, m.MessageContentJP, m.MessageContentKH, m.MessageContentKO, m.MessageContentEN AS [MessageContentHITG], m.MessageContentTH, m.MessageContentVN, m.MessageContentCS, m.MessageContentCH
FROM Affiliate_N88.dbo.Messages m WITH (NOLOCK)
	LEFT JOIN dbo.Messages m1 WITH(NOLOCK) ON m.MessageId = m1.MessageId
WHERE m1.MessageId IS NULL
GO


-- Log type
INSERT INTO dbo.LogType (TypeId, TypeName, Description)
SELECT t.TypeId, t.TypeName, t.Description
FROM Affiliate_N88.dbo.LogType t WITH (NOLOCK)
	LEFT JOIN dbo.LogType lt WITH(NOLOCK) ON t.TypeId = lt.TypeId
WHERE lt.TypeId IS NULL
GO


-- Log action
INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description)
SELECT t.ActionId, t.ActionTypeId, t.SPName, t.Description
FROM Affiliate_N88.dbo.LogAction t WITH (NOLOCK)
	LEFT JOIN dbo.LogAction la WITH (NOLOCK) ON la.ActionId = t.ActionId
WHERE la.ActionId IS NULL
GO