USE Affiliate_N8B
GO

INSERT INTO dbo.Deductions (DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted)
SELECT 10, 'Platform Fee', 0.17, 0, 0
UNION ALL SELECT 11, 'Operational Fee', 0.07, 0, 0
UNION ALL SELECT 12, 'Banking Fee', 0.02, 0, 0
UNION ALL SELECT 13, 'Exchange Win Loss Share', 0, 0, 0
UNION ALL SELECT 14, 'Exchange Commission Share', 0, 0, 0
GO

INSERT INTO dbo.CommGroup (GroupID, GroupName, Creator, IsDeleted, Description)
SELECT 1, 'Default', 8, 0, 'Default System Commission Group'
UNION ALL SELECT 2, 'NoCommission', 35915769, 0, 'Group for all zero commission/closed affiliates'
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
SELECT 1, '2020-02-29', 1, 0, 10, 0, 1, 0.15
UNION ALL SELECT 1, '2020-02-29', 2, 11, 100000000000000, 2, 1000000000, 0.3
UNION ALL SELECT 2, '2020-02-29', 1, 0, 100000000000000, 0, 1000000000, 0
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
SELECT GroupID, '2020-02-29', DeductionID, DeductedPercentage, ProductId, GroupProductId FROM dbo.DeductionSetting
GO

INSERT INTO dbo.Products (ProductId, ProductName, ProductPrefix, IsIBC, Enabled, IsTest, ReleasedDate)
SELECT 1, 'Sportsbook', 'SB', 1, 1, 0, '2020-02-01'
UNION ALL SELECT 2, 'Number Game', 'NG', 1, 1, 0, '2020-02-01'
UNION ALL SELECT 3, 'Virtual Sports', 'VS', 1, 1, 0, '2020-02-01'
UNION ALL SELECT 4, 'Virtual Sports 2', 'VS2', 1, 1, 0, '2020-02-01'
UNION ALL SELECT 5, 'RNG Keno', 'KN', 1, 1, 0, '2020-02-01'
UNION ALL SELECT 6, 'Allbet', 'AB', 1, 1, 0, '2020-02-01'
UNION ALL SELECT 7, 'RNG Casino', 'CS', 1, 1, 0, '2020-02-01'
UNION ALL SELECT 8, 'PP', 'PP', 1, 1, 0, '2020-02-01'
GO

DECLARE @currentDate DATETIME
SET @currentDate = CURRENT_TIMESTAMP

INSERT INTO dbo.Affiliate_User (CreateDate, Creator, GroupId, Closed, LoginCount, IPLogin, LastLogged, On_SessionId, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName)
SELECT @currentDate, 35915769, 1, Closed, LoginCount, IPLogin, LastLogged, On_SessionId, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName
FROM Affiliate_12BET.dbo.Affiliate_User WITH (NOLOCK)
WHERE custId IN (360418, 862400,1000000042,1000000041,1000000044,1000000036)

INSERT INTO dbo.AffGroupInfo (GroupName, GroupDesc, CreateDate, ModifyDate, DisplayOrder, Creator)
SELECT GroupName, GroupDesc, @currentDate, @currentDate, DisplayOrder, 35915769
FROM Affiliate_12BET.dbo.AffGroupInfo WITH (NOLOCK)
WHERE GroupId IN (119,120)

INSERT INTO dbo.AffFunctionInfo (FuncName,FuncNote,FuncDesc,FuncRender,CreateDate,ModifyDate,DisplayOrder,Creator,FileNames)
SELECT FuncName,FuncNote,FuncDesc,FuncRender,@currentDate,@currentDate,DisplayOrder,35915769,FileNames
FROM Affiliate_12BET.dbo.AffFunctionInfo WITH (NOLOCK)

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
SELECT SName, REPLACE(SValue, '12BETAFF', 'N8BAFF')
FROM Affiliate_12BET.dbo.SystemSettings WITH (NOLOCK)
WHERE SName NOT IN ('AFF_CutOffReportDate', 'AFF_CheckData_API', 'AFF_OldReportDate')
GO

INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('SiteName', 'N8B')
	,('AffCurrency', '51')
	,('MemberInfoLastImportedTime', '2020-02-01')
	,('LastImportedTime_ExchangeOanda', '2020-02-01')
	,('SoftLaunchDate', '2020-01-01')
	,('LaunchDate', '2020-03-01')
GO

INSERT INTO dbo.Market (MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName)
VALUES
	(N'en-GB', N'English (Europe)', N'English (Europe)', N'eneuro', N'English (Europe)'),
	(N'en-US', N'English', N'English', N'en', N'English'),
	(N'es-ES', N'Spanish', N'Español', N'es', N'Spanish'),
	(N'hi-IN', N'English (India)', N'English (India)', N'hien', N'English (India)'),
	(N'id-ID', N'Indonesian', N'Indonesia', N'id', N'Bahasa Indonesia'),
	(N'ja-JP', N'Japanese', N'日本', N'jp', N'Japanese'),
	(N'ko-KR', N'Korean', N'한국어', N'ko', N'Korean'),
	(N'th-TH', N'Thai', N'ภาษาไทย', N'th', N'Thai'),
	(N'vi-VN', N'Vietnamese', N'Tiếng Việt', N'vn', N'Vietnamese'),
	(N'zh-CN', N'Chinese Simplified', N'中文简体', N'cs', N'Chinese Simplified'),
	(N'zh-TW', N'Chinese Traditional', N'中文繁体', N'ch', N'Chinese Traditional')
GO

INSERT INTO dbo.Messages (MessageId,MessageTypeId,Description,MessageContentEN,MessageContentCS,MessageContentCH,MessageContentID,MessageContentVN,MessageContentTH,MessageContentKO,MessageContentES,MessageContentJP,MessageContentHIEN,MessageContentENEURO)
SELECT MessageId,MessageTypeId,Description,MessageContentEN,MessageContentCS,MessageContentCH,MessageContentID,MessageContentVN,MessageContentTH,MessageContentKO,MessageContentES,MessageContentJP,MessageContentHIEN,MessageContentENEURO
FROM Affiliate_12BET.dbo.Messages WITH (NOLOCK)
GO

UPDATE dbo.Messages WITH (ROWLOCK)
SET MessageContentVN = CASE MessageId
		WHEN 301 THEN N'Tài khoản này hiện có 1 yêu cầu thanh toán chờ xử lý. Vui lòng hoàn tất yêu cầu giao dịch này trước!'
		WHEN 501 THEN N'Đây không phải là giao dịch rút tiền.'
		WHEN 502 THEN N'Xin lỗi, bạn không có quyền trên giao dịch này.'
		WHEN 1 THEN N'Email này đã được sử dụng. Vui lòng chọn cái khác!'
		WHEN 2 THEN N'Tạo tài khoản không thành công. Vui lòng thử lại.'
		WHEN 3 THEN N'Tên tài khoản này đã được sử dụng. Vui lòng chọn cái khác!'
		WHEN 101 THEN N'Sai tên đăng nhập/ mật khẩu'
		WHEN 102 THEN N'Tài khoản bị đóng'
		WHEN 103 THEN N'Tài khoản bị khóa'
		WHEN 104 THEN N'Tài khoản chưa được duyệt.'
		WHEN 202 THEN N'Tài khoản bị đóng. Vui lòng liên hệ với quản lý cuả bạn!'
		WHEN 203 THEN N'Tài khoản chưa được duyệt. Vui lòng liên hệ với quản lý cuả bạn!'
		WHEN 204 THEN N'Email dùng để nhận mật khẩu mới không không hợp lệ.'
		WHEN 205 THEN N'Khôi phục mật khẩu không thành công. Vui lòng thử lại!'
		WHEN 303 THEN N'Quá trình cập nhật không thành công. Vui lòng thử lại!'
		WHEN 304 THEN N'Affiliate này không tồn tại!'
		WHEN 503 THEN N'Cập nhật không thành công. Vui lòng thử lại!'
ELSE MessageContentVN END
GO

INSERT INTO dbo.BannerTypes (Type,Value,DisplayOrder)
SELECT Type,Value,DisplayOrder
FROM Affiliate_12BET.dbo.BannerTypes_1 WITH (NOLOCK)
GO

UPDATE dbo.BannerTypes WITH (ROWLOCK)
SET Value = 'English (india)'
WHERE Type = 'Language' AND Value = 'Republic of India'
GO


INSERT INTO dbo.IPv4Addresses ([From], [To], Code2, Code3, Country)
SELECT [From], [To], Code2, Code3, Country
FROM Affiliate_12BET.dbo.IPv4Addresses WITH (NOLOCK)
GO

INSERT INTO dbo.TransType (TypeId, TypeName, TypeDesc)
SELECT TypeId, TypeName, TypeDesc
FROM Affiliate_12BET.dbo.TransType WITH (NOLOCK)
WHERE TypeId IN (201, 202, 203)