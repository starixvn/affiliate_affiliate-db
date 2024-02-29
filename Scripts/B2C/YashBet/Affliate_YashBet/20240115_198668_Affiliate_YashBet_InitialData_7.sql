/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Support new Aff Yashbet
		2. Initial data  DB Affiliate_YashBet
*/

USE Affiliate_YashBet
GO

-- Initial Settings info
INSERT INTO dbo.SystemSettings (SName, SValue)
SELECT T.SName, T.SValue
FROM (
	SELECT 'AFF_BalPlayerAUD' AS SName, 'N8YAFFPlayerAUD' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerCHF' AS SName, 'N8YAFFPlayerCHF' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerEURO' AS SName, 'N8YAFFPlayerEURO' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerGBP' AS SName, 'N8YAFFPlayerGBP' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerIN' AS SName, 'N8YAFFPlayerIN' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerINH' AS SName, 'N8YAFFPlayerINH' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerINR' AS SName, 'N8YAFFPlayerINR' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerJPY' AS SName, 'N8YAFFPlayerJPY' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerRM' AS SName, 'N8YAFFPlayerRM' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerRMB' AS SName, 'N8YAFFPlayerRMB' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerSD$' AS SName, 'N8YAFFPlayerSD$' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerTB' AS SName, 'N8YAFFPlayerTB' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerUS$' AS SName, 'N8YAFFPlayerUS$' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerUUS' AS SName, 'N8YAFFPlayerUUS' AS SValue UNION ALL
	SELECT 'AFF_BalPlayerWON' AS SName, 'N8YAFFPlayerWON' AS SValue UNION ALL
	SELECT 'AFF_BaseCurrencies' AS SName, '61:INR,74:BDT' AS SValue UNION ALL
	SELECT 'AFF_CommissionDate' AS SName, '2023-12-31' AS SValue UNION ALL
	SELECT 'AFF_PaymentCurrencies' AS SName, '61:INR,74:BDT' AS SValue UNION ALL
	SELECT 'AFF_SupportedCurrencies' AS SName, '61:INR,74:BDT' AS SValue UNION ALL
	SELECT 'AffCurrency' AS SName, '61' AS SValue UNION ALL
	SELECT 'BrandName' AS SName, 'YashBet' AS SValue UNION ALL
	SELECT 'LastImportedTime_ExchangeOanda' AS SName, '2024-01-01' AS SValue UNION ALL
	SELECT 'LaunchDate' AS SName, '2024-01-01' AS SValue UNION ALL
	SELECT 'MaxSubLevel' AS SName, '1000' AS SValue UNION ALL
	SELECT 'MemberInfoLastImportedTime' AS SName, '2023-10-09 8:11:11' AS SValue UNION ALL
	SELECT 'MemberInfoLastUpdatedTime' AS SName, '2023-05-31 0:00:00' AS SValue UNION ALL
	SELECT 'P2P_CutOffDate' AS SName, '2024-01-01' AS SValue UNION ALL
	SELECT 'Payment_Method' AS SName, 'Player:YashBet Player Account' AS SValue UNION ALL
	SELECT 'Payment_MinAmount' AS SName, '100' AS SValue UNION ALL
	SELECT 'Report_CutOffDate' AS SName, '2024-01-01' AS SValue UNION ALL
	SELECT 'SiteName' AS SName, 'N8Y' AS SValue UNION ALL
	SELECT 'SoftLaunchDate' AS SName, '2024-01-01' AS SValue UNION ALL
	SELECT 'TimeZone' AS SName, '8' AS SValue 
)t
	LEFT JOIN dbo.SystemSettings ss WITH (NOLOCK) ON ss.SName = t.SValue
WHERE ss.SValue IS NULL
GO
-- Initial Products info
INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest,ReleasedDate,RefProductId,DataSource, IsP2P)
	SELECT Type AS ProductId, TypeName AS ProductName,'',0,1,0,'2024-01-01',Type AS RefProductId,'TpBetRecord' AS DataSource, CASE WHEN  t.Type IN (41, 42) THEN 1 ELSE 0 END AS IsP2P
	FROM bodb_YashBet.dbo.TpGameType t WITH (NOLOCK)
		LEFT JOIN dbo.Products p  WITH (NOLOCK) ON p.ProductId = t.Type
	WHERE p.ProductId IS NULL
GO
-- Initial mapping exchange info
INSERT INTO dbo.TpExchange (TpExchangeId, ExchangeId)
SELECT T.TpExchangeId, T.ExchangeId
FROM (
	SELECT 74 AS TpExchangeId, 97 AS ExchangeId
)t 
	LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON T.TpExchangeId = te.TpExchangeId
											AND T.ExchangeId = te.ExchangeId
WHERE te.TpExchangeId IS NULL
GO

INSERT INTO dbo.Exchange (ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, THB, IDR, MultipliedBy)
SELECT e.ExchangeId, e.Code, e.ActualRate, e.VND, e.EUR, e.USD, e.CNY, e.MYR, e.THB, e.IDR, e.MultipliedBy
FROM Affiliate_N88.dbo.Exchange e WITH(NOLOCK)
	LEFT JOIN dbo.Exchange et WITH(NOLOCK) ON e.ExchangeId = et.ExchangeId
WHERE et.ExchangeId IS NULL

GO
-- Initial account and policy info
DECLARE @LaunchDate DATETIME = '2024-01-01'
---Prod env
INSERT INTO dbo.Affiliate_User (PageAccess, CreateDate, Creator, GroupId, Closed, LoginCount, IPLogin, LastLogged, On_SessionId, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName)
SELECT t.PageAccess, @LaunchDate, t.Creator, t.GroupId, t.Closed, t.LoginCount, t.IPLogin, @LaunchDate, t.On_SessionId, t.UserName, t.UserPwd, t.RoleId, '2024-05-01', t.FirstName, t.LastName
FROM (
	VALUES ( NULL, '2020-05-07 6:25:12', '35915769', '1001', '0', '0', '210.57.35.24', '2024-01-18 3:15:00', '0', 'AAStarixQC01', '56E8A2D78170E87C928E480797CC73', '6', '2022-08-07 0:03:42', NULL, NULL),
       ( NULL, '2020-05-07 6:25:12', '35915769', '1001', '1', '5', '125.227.140.97', '2020-10-06 5:01:00', '0', 'AAStarixQC02', '9AF8857E8576B8A8C184C7679BC58F', '6', '2021-09-22 23:49:16', NULL, NULL)
) AS t (PageAccess, CreateDate, Creator, GroupId, Closed, LoginCount, IPLogin, LastLogged, On_SessionId, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName) 
	LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON u.UserName = t.UserName
WHERE u.UserName IS  NULL


INSERT INTO dbo.AffFunctionInfo (FuncName, FuncNote, FuncDesc, FuncRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentId, FileNames)
SELECT t.FuncName, t.FuncNote, t.FuncDesc, t.FuncRender, @LaunchDate AS CreateDate, @LaunchDate AS ModifyDate, t.DisplayOrder, t.Creator, t.ParentId, t.FileNames
FROM (
	VALUES ('[UserControl]', '', 'User Control', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'UserControl/ListUser.aspx; UserControl/EditUser.aspx; UserControl/AddUser.aspx; UserControl/AddUserExist.aspx; UserControl/ListDepartment.aspx; UserControl/AddDepartment.aspx; UserControl/EditDepartment.aspx;UserControl/EditAdminPolicy.aspx; UserControl/EditGroupPolicy.aspx; UserControl/ListUserInDept.aspx; UserControl/UpdateMultiAdmins.aspx'),
       ('[Affiliate]', '', 'Affiliate', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'UserInfo/AffiliateList.aspx; UserInfo/AffiliateUpd.aspx; UserInfo/AccOverview.aspx; UserInfo/MemberList.aspx; DailyEarning.aspx; DailyEarningDetail.aspx; EarningsHistory.aspx; MemberList.aspx; PlayersDetail.aspx; StatementUpd.aspx; Customer/AffDefault.aspx; Customer/Statistics.aspx; Customer/AffiliateInfo.aspx; UserInfo/MediaStatistics.aspx; UserInfo/note.aspx; Others/EmailHistory.aspx; Others/ViewEmailDetails.aspx;UserInfo/MemberListAll.aspx;GroupSetting/AssignGroup.aspx;UserInfo/MemberList.aspx;'),
       ('[Payment]', '', 'Payment', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'Payment/PaymentRequest.aspx; Payment/PaymentUpdate.aspx; Payment/Payment_.aspx'),
       ('[Media]', '', 'Media', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'Media/Listbanner.aspx; Media/AddBanner.aspx'),
       ('[AffEx.Rate]', '', 'Affiliate Exchange', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'Exchange/AffRate.aspx; Exchange/AffEditRate.aspx'),
       ('[HotNews]', '', 'HotNews', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'Others/Message.aspx'),
       ('[RevenueGroup]', '', 'Revenue Group', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'GroupSetting/GroupSetting.aspx; GroupSetting/AddGroup.aspx; GroupSetting/EditGroup.aspx;'),
       ('[AffReport]', '', 'Affiliate Report', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'Home/Home.aspx;Report/MemberReport.aspx;Report/AffiliateReport.aspx;Report/MemberStaticticsReport.aspx;Report/AffiliateQMReport.aspx;Report/Performance.aspx;Report/PerformanceReportByAffiliate.aspx'),
       ('[Note]', NULL, 'Manage Notes', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'UserInfo/Note.aspx;'),
       ('[SecurityQA]', NULL, 'Security Q&A', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, ''),
       ('[Domain]', '', 'Domain Control', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'Domain/12BetDomain.aspx;Domain/Add12BetDomain.aspx;Domain/AddAffiliateDomain.aspx;Domain/AffiliateDomain.aspx;Domain/DomainControl.aspx;Domain/DomainControlIns.aspx;Domain/DomainControlUpd.aspx;Domain/Edit12BetDomain.aspx;Domain/EditAffiliateDomain.aspx;'),
       ('[ActiveMembers]', '', 'Active Members', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, 'UserInfo/MemberActiveList.aspx'),
       ('[MemberEmail]', '', 'Member''s Email', '3', '2020-05-07 06:25:11.7330000', '2020-05-07 06:25:11.7330000', '1', '35915769', NULL, ''),
       ('[TransferPlayerSetting]', '', 'Transfer Balance For Player Setting', '3', '2021-11-19 04:47:34.4670000', '2021-11-19 04:47:34.4670000', '7', NULL, NULL, NULL),
       ('[TransferPlayerReport]', '', 'Transfer Balance For Player Report', '3', '2021-11-19 04:47:34.4670000', '2021-11-19 04:47:34.4670000', '7', NULL, NULL, NULL)
)AS t(FuncName, FuncNote, FuncDesc, FuncRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentId, FileNames)
	LEFT JOIN dbo.AffFunctionInfo f WITH (NOLOCK) ON t.FuncName = f.FuncName
WHERE f.FuncName IS NULL
;
INSERT INTO dbo.AffMemberPolicy (CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT t.CustId, t.FuncId, 3 AS Policy, @LaunchDate AS CreateDate, @LaunchDate AS ModifyDate, 1000000000 as Creator
FROM (
	SELECT u.CustId, f.FuncId
	FROM dbo.Affiliate_User u WITH (NOLOCK)
		CROSS JOIN dbo.AffFunctionInfo f WITH (NOLOCK)
)t
	LEFT JOIN dbo.AffMemberPolicy a WITH(NOLOCK) ON a.CustId = t.CustId 
											AND a.FuncId = t.FuncId
WHERE a.CustId IS NULL

INSERT INTO dbo.AffGroupInfo (GroupName, GroupDesc, CreateDate, ModifyDate, DisplayOrder, Creator)
SELECT t.GroupName, t.GroupDesc, @LaunchDate AS CreateDate, @LaunchDate AS ModifyDate, t.DisplayOrder, 1000000000 as Creatorr
FROM(
	VALUES ('None', 'None', '5'),
       ('IT', 'IT dept', '5')
)AS t(GroupName, GroupDesc,  DisplayOrder)
	LEFT JOIN AffGroupInfo a WITH (NOLOCK)ON T.GroupName = a.GroupName
WHERE a.GroupName IS NULL
;
INSERT INTO dbo.AffGroupPolicy (GroupId, FuncId, Policy, CreateDate, ModifyDate, Creator)
SELECT t.GroupId, t.FuncId, 3 AS Policy, @LaunchDate AS CreateDate, @LaunchDate AS ModifyDate, 1000000000 as Creator
FROM (
	SELECT g.GroupId, f.FuncId
	FROM dbo.AffGroupInfo g WITH (NOLOCK)
		CROSS JOIN dbo.AffFunctionInfo f WITH (NOLOCK)
)t
	LEFT JOIN dbo.AffGroupPolicy a WITH(NOLOCK) ON a.GroupId = t.GroupId 
											AND a.FuncId = t.FuncId
WHERE a.GroupId IS NULL;
-- Initial GroupComm info
INSERT INTO dbo.CommGroup (GroupName, Description, Creator, CreatedDate, IsPrivate, IsDeleted, SubCommRate)
SELECT t.GroupName, t.Description, 1000000000 AS Creator, @LaunchDate CreatedDate, t.IsPrivate, t.IsDeleted, t.SubCommRate
FROM (
	VALUES ('Default', 'Default System Revenue Group','0', '0', '0.10000000') 
)AS t (GroupName, Description, IsPrivate, IsDeleted, SubCommRate)
	LEFT JOIN dbo.CommGroup c WITH (NOLOCK) ON c.GroupName = t.GroupName
WHERE c.GroupId IS NULL

-- Initial data AffiliateCode info
GO
	DECLARE @n INT = 10000
		   ,@batch INT = 5000
		   ,@msg VARCHAR(200)
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
GO
INSERT INTO dbo.AffType (TypeId, Name, Description, CreatedDate, Creator, IsShown)
	SELECT t.TypeId, t.Name, t.Description, t.CreatedDate, t.Creator, t.IsShown
	FROM (VALUES (1, N'Asian', N'Asian Affiliate', '2020-04-22 04:53:06.657',1000000000, 1)
	)AS t(TypeId, Name, Description, CreatedDate, Creator, IsShown)
	LEFT JOIN dbo.AffType a WITH (NOLOCK) ON T.TypeId = a.TypeId 
	WHERE a.TypeId IS NULL
GO

INSERT INTO dbo.Deductions (DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted, DeductedAmount, IsDeductedPercent, Commission)
	SELECT t.DeductionId, t.DeductionName, t.DeductedPercentage, t.IsTest, t.IsDeleted, t.DeductedAmount, t.IsDeductedPercent, t.Commission
	FROM (
		VALUES ('10', 'Platform Fee', '0.00000000', '0', '0', NULL, '1', '0.00000000'),
		   ('11', 'Operational Fee', '0.07000000', '0', '0', NULL, '1', '0.00000000'),
		   ('13', 'Deposit Fee', '0.02000000', '0', '0', NULL, '1', '0.00000000'),
		   ('14', 'Withdrawal Fee', '0.02000000', '0', '0', NULL, '1', '0.00000000'),
		   ('15', 'P2P Fee', '0.10000000', '0', '0', NULL, '1', '0.30000000')
	 )AS t (DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted, DeductedAmount, IsDeductedPercent, Commission)
		LEFT JOIN dbo.Deductions d WITH (NOLOCK) ON D.DeductionId = T.DeductionId
	 WHERE D.DeductionId IS NULL 
GO
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
	SELECT t.GroupId, t.DeductionId, t.ProductId, t.GroupProductId,t.DeductedPercentage, t.DeductedAmount, t.IsDeductedPercent
	FROM (
		VALUES ('1', '10', '1', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '2', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '3', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '4', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '5', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '6', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '7', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '8', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '9', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '10', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '11', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '12', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '13', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '14', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '15', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '16', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '17', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '18', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '19', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '20', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '21', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '22', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '23', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '24', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '25', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '26', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '27', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '28', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '29', '2', '0.10000000', '0.0000', '1'),
			   ('1', '10', '30', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '31', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '32', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '33', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '34', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '35', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '36', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '37', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '38', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '39', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '40', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '44', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '45', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '46', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '47', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '48', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '49', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '50', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '51', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '52', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '53', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '54', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '55', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '56', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '57', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '58', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '59', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '60', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '61', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '62', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '63', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '64', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '65', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '66', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '67', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '68', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '69', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '70', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '71', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '72', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '73', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '74', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '75', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '76', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '77', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '78', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '79', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '80', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '81', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '82', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '83', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '84', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '85', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '86', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '87', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '88', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '89', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '90', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '91', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '93', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '94', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '95', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '96', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '97', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '98', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '99', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '100', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '101', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '102', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '103', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '104', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '105', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '106', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '107', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '108', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '109', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '110', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '111', '1', '0.12000000', '0.0000', '1'),
			   ('1', '10', '112', '1', '0.12000000', '0.0000', '1'),
			   ('1', '11', '0', '1', '0.00000000', '0.0000', '1'),
			   ('1', '13', '0', '1', '0.03000000', '0.0000', '1'),
			   ('1', '14', '0', '1', '0.03000000', '0.0000', '1')
	)AS t (GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
	LEFT JOIN dbo.DeductionSetting ds WITH (NOLOCK) ON ds.GroupId = T.GroupId
													AND ds.DeductionId = T.DeductionId
													AND ds.ProductId = T.ProductId
	WHERE ds.DeductionId IS NULL
GO
	INSERT INTO dbo.TierSetting (GroupId, TierId, MinAmount, MaxAmount, MinAM, MaxAM, Commission, GroupProductId, IsActivePlayerSum)
		SELECT t.GroupId, t.TierId, t.MinAmount, t.MaxAmount, t.MinAM, t.MaxAM, t.Commission, t.GroupProductId, t.IsActivePlayerSum
		FROM (
			VALUES ('1', '1', '0.0000', '100000000000.0000', '0', '1000000000', '0.00000000', '1', '1'),
			 ('1', '1', '0.0000', '100000000000.0000', '0', '1000000000', '0.00000000', '2', '1')
	   )AS t (GroupId, TierId, MinAmount, MaxAmount, MinAM, MaxAM, Commission, GroupProductId, IsActivePlayerSum)
		   LEFT JOIN dbo.TierSetting ts WITH (NOLOCK) ON t.GroupId = ts.GroupId
														AND t.GroupProductId = ts.GroupProductId
														AND t.TierId = ts.TierId
		WHERE ts.GroupId IS NULL
GO
	INSERT INTO dbo.StraightSetting (GroupId, ProductId, GroupProductId, DeductedPercentage, Commission)
		SELECT t.GroupId, t.ProductId, t.GroupProductId, t.DeductedPercentage, t.Commission
		FROM (
			VALUES ('1', '41', '1', '0.10000000', '0.30000000'),
				('1', '42', '1', '0.10000000', '0.30000000')
		)AS t(GroupId, ProductId, GroupProductId, DeductedPercentage, Commission)
			LEFT JOIN dbo.StraightSetting st WITH (NOLOCK) ON st.GroupId = t.GroupId AND st.ProductId = t.ProductId
		WHERE st.ProductId IS NULL
GO
INSERT INTO dbo.IPv4Addresses ([From], [To], Code2, Code3, Country)
	SELECT t.[From], t.[To], t.Code2, t.Code3, t.Country
	FROM Affiliate_N88.dbo.IPv4Addresses t WITH (NOLOCK)
		LEFT JOIN dbo.IPv4Addresses e WITH (NOLOCK) ON T.[From] = e.[From]
														AND T.[To] = e.[To]
	WHERE e.[From] IS NULL
	
GO

INSERT INTO dbo.LogType (TypeId, TypeName, Description)
	SELECT t.TypeId, t.TypeName, t.Description
	FROM(
		VALUES ('1', 'RevenueGroup', 'Setting for Revenue Group'),
		   ('2', 'UserInfo', 'User Info'),
		   ('3', 'Transaction', 'Transaction'),
		   ('4', 'Payout', 'Payout'),
		   ('5', 'Permission', 'Permission'),
		   ('6', 'Player', 'Player'),
		   ('7', 'Banner', 'Banner'),
		   ('8', 'Email', 'Email'),
		   ('9', 'Message', 'Message'),
		   ('10', 'ExchangeRate', 'Exchange Rate'),
		   ('11', 'UserNote', 'User Note'),
		   ('12', 'LoginAdmin', 'Login Admin'),
		   ('13', 'LoginAffiliate', 'Login Affiliate'),
		   ('14', 'LogoutAdmin', 'Logout Admin'),
		   ('15', 'LogoutAffiliate', 'Logout Affiliate'),
		   ('16', 'Password', 'Password'),
		   ('17', 'Adjustment', 'Adjustment'),
		   ('18', 'Member', 'Member'),
		   ('19', 'UserControl', 'User Control'),
		   ('20', 'Portal', 'Affiliate Portal'),
		   ('21', 'LicenseeDomain', 'LicenseeDomain'),
		   ('22', 'AffDomain', 'AffDomain'),
		   ('23', 'DomainControl', 'DomainControl'),
		   ('24', 'Affiliate', 'Affiliate'),
		   ('25', 'AffInfo', 'AffInfo'),
		   ('26', 'LandingPage', 'Landing Page'),
		   ('27', 'Text', 'Text')
	)AS t (TypeId, TypeName, Description)
		LEFT JOIN dbo.LogType lt WITH(NOLOCK) ON T.TypeId = lt.TypeId
	WHERE lt.TypeId IS NULL
GO
	INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description)
	SELECT t.ActionId, t.ActionTypeId, t.SPName, t.Description
	FROM (
		VALUES ('42', '25', 'Aff_Admin_Affiliate_Approved', NULL),
			   ('43', '25', 'Aff_Admin_Affiliate_Favorite_Upd', NULL),
			   ('24', '16', 'Aff_Admin_Affiliate_Password_Upd', NULL),
			   ('7', '3', 'Aff_Admin_AffiliateAdjustment_Ins', NULL),
			   ('37', '25', 'Aff_Admin_AffiliateAffType_Upd', NULL),
			   ('38', '25', 'Aff_Admin_AffiliateClosed_Upd', NULL),
			   ('29', '22', 'Aff_Admin_AffiliateDomain_Del', NULL),
			   ('30', '22', 'Aff_Admin_AffiliateDomain_Ins', NULL),
			   ('31', '22', 'Aff_Admin_AffiliateDomain_Upd', NULL),
			   ('39', '25', 'Aff_Admin_AffiliateInfo_Upd', NULL),
			   ('35', '24', 'Aff_Admin_AffiliateNote_Ins', NULL),
			   ('36', '24', 'Aff_Admin_AffiliateNote_Upd', NULL),
			   ('10', '4', 'Aff_Admin_AffiliatePaymentRequest_Upd', NULL),
			   ('40', '25', 'Aff_Admin_AffiliatePreferredLanguage_Upd', NULL),
			   ('41', '25', 'Aff_Admin_AffiliateStatus_Upd', NULL),
			   ('11', '7', 'Aff_Admin_Banner_Del', NULL),
			   ('12', '7', 'Aff_Admin_Banner_Ins', NULL),
			   ('13', '7', 'Aff_Admin_Banner_Upd', NULL),
			   ('25', '16', 'Aff_Admin_ChangePassword', NULL),
			   ('1', '1', 'Aff_Admin_CommGroup_Assign', NULL),
			   ('2', '1', 'Aff_Admin_CommGroup_Del', NULL),
			   ('3', '1', 'Aff_Admin_CommGroup_Ins', NULL),
			   ('4', '1', 'Aff_Admin_CommGroup_Upd', NULL),
			   ('32', '23', 'Aff_Admin_DomainControl_Del', NULL),
			   ('33', '23', 'Aff_Admin_DomainControl_Ins', NULL),
			   ('34', '23', 'Aff_Admin_DomainControl_Upd', NULL),
			   ('15', '8', 'Aff_Admin_EmailHistory_Del', NULL),
			   ('44', '26', 'Aff_Admin_LandingPage_Del', NULL),
			   ('45', '26', 'Aff_Admin_LandingPage_Ins', NULL),
			   ('46', '26', 'Aff_Admin_LandingPage_Upd', NULL),
			   ('26', '21', 'Aff_Admin_LicenseeDomain_Del', NULL),
			   ('27', '21', 'Aff_Admin_LicenseeDomain_Ins', NULL),
			   ('28', '21', 'Aff_Admin_LicenseeDomain_Upd', NULL),
			   ('19', '12', 'Aff_Admin_Login', NULL),
			   ('16', '9', 'Aff_Admin_Message_Del', NULL),
			   ('17', '9', 'Aff_Admin_Message_Ins', NULL),
			   ('18', '9', 'Aff_Admin_Message_Upd', NULL),
			   ('47', '27', 'Aff_Admin_Text_Del', NULL),
			   ('48', '27', 'Aff_Admin_Text_Ins', NULL),
			   ('49', '27', 'Aff_Admin_Text_Upd', NULL),
			   ('14', '8', 'Aff_EmailHistoryIns', NULL),
			   ('6', '2', 'Aff_User_Affiliate_Ins', NULL),
			   ('21', '16', 'Aff_User_ForgotPassword', NULL),
			   ('20', '13', 'Aff_User_Login_ResultUpd', NULL),
			   ('8', '4', 'Aff_User_PaymentRequest_Ins', NULL),
			   ('9', '4', 'Aff_User_PaymentRequest_Upd', NULL),
			   ('22', '16', 'Aff_User_RecoverPassWord', NULL),
			   ('5', '2', 'Aff_User_UserInfoUpd', NULL),
			   ('23', '16', 'Aff_User_VerificationUpd', NULL)
		) t (ActionId, ActionTypeId, SPName, Description)
			LEFT JOIN dbo.LogAction la WITH (NOLOCK) ON la.ActionId = T.ActionId
		WHERE la.ActionId IS NULL
GO
--- Initial Message Error
INSERT INTO dbo.Messages (MessageId, MessageTypeId, Description, MessageContentEN, MessageContentCS, MessageContentCH, MessageContentID, MessageContentVN, MessageContentTH, MessageContentKO, 
		MessageContentES, MessageContentJP, MessageContentHIEN, MessageContentENEURO, MessageContentMS, MessageContentKH, MessageContentBN
	)
	SELECT m.MessageId, m.MessageTypeId, m.Description, m.MessageContentEN, m.MessageContentCS, m.MessageContentCH, m.MessageContentID, m.MessageContentVN, m.MessageContentTH, m.MessageContentKO
		,m.MessageContentES, m.MessageContentJP, m.MessageContentHIEN, m.MessageContentENEURO, m.MessageContentMS, m.MessageContentKH, m.MessageContentBN
	FROM Affiliate_N88.dbo.Messages m WITH (NOLOCK)
		LEFT JOIN dbo.Messages m1 WITH(NOLOCK) ON m.MessageId = m1.MessageId
	WHERE m1.MessageId IS NULL
GO
SELECT *
FROM affiliate_N88.dbo.TransType m WITH (NOLOCK)

INSERT INTO dbo.Market (MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName)
	SELECT t.MarketId, t.MarketName, t.MarketNativeName, t.ShortedCode, t.DisplayName
	FROM (
		VALUES (N'bn-BD', N'Bangladeshi', N'বাংলাদেশী', N'bn', N'Bangladeshi'),
				(N'en-US', N'English', N'English', N'en', N'English'),
				(N'hi-IN', N'Hindi', N'हिन्दी', N'hi', N'Hindi')
	) AS t(MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName)
		LEFT JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = T.MarketId
	WHERE m.MarketId IS NULL
GO

INSERT INTO dbo.TransType (TypeId, TypeName, TypeDesc)
	SELECT t.TypeId, t.TypeName, t.TypeDesc
	FROM (
		VALUES ('201', 'Monthly Earning', 'Affiliate Monthly Earning Transfer'),
				('202', 'Payment', 'Affiliate Payment'),
				('203', 'Adjustment', 'Affiliate Balance Adjustmentr'),
				('204', 'Revenue Share', 'Affiliate Monthly Revenue Share Transfer')
	)AS t (TypeId, TypeName, TypeDesc)
		LEFT JOIN dbo.TransType tt WITH (NOLOCK) ON tt.TypeId = T.TypeId
	WHERE tt.TypeId IS NULL
;
