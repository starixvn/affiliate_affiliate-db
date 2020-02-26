/*===== Affiliate_N8G =====*/
USE Affiliate_N8G
GO


INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, NextGroupProductId, NextDeductedPercentage)
SELECT GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, NextGroupProductId, NextDeductedPercentage
FROM Affiliate_N8B.dbo.DeductionSetting WITH (NOLOCK)
WHERE GroupId = 1 AND DeductionId = 10
GO

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, ProductId, GroupProductId, DeductedPercentage)
SELECT GroupId, MonthDate, DeductionId, ProductId, GroupProductId, DeductedPercentage
FROM Affiliate_N8B.dbo.DeductionSettingHistory WITH (NOLOCK)
WHERE GroupId = 1 AND DeductionId = 10 AND MonthDate = '2020-02-29'
GO

INSERT INTO dbo.Messages (MessageId, MessageTypeId, MessageContentEN)
SELECT 504, 3, N'Invalid Balance Account.' UNION ALL
SELECT 505, 3, N'Sorry, you do not have enough money to withdraw.' UNION ALL
SELECT 506, 3, N'Sorry, amount is invalid.' UNION ALL
SELECT 507, 3, N'Sorry, only Player Account method is supported. Please contact your Administrator.' UNION ALL
SELECT 508, 3, N'Sorry, this affiliate does not have Player Account. Please contact your Administrator.' UNION ALL
SELECT 509, 3, N'Sorry, this affiliate does not have Player Account.' UNION ALL
SELECT 510, 3, N'Invalid request amount! Amount must be between {MinAmount} and {MaxAmount}' UNION ALL
SELECT 511, 3, N'Insert transaction failed. Please try again!'
GO

UPDATE dbo.Messages WITH (ROWLOCK)
SET MessageContentVN = CASE MessageId
	WHEN 505 THEN N'Xin lỗi, số tiền trong tài khoản hiện không đủ.'
	WHEN 506 THEN N'Xin lỗi, giá trị không hợp lệ.'
	WHEN 507 THEN N'Xin lỗi, hệ thống chỉ hỗ trợ rút tiền thông qua tài khoản cá cược. Vui lòng liên hệ với quản lý của bạn.'
	WHEN 508 THEN N'Xin lỗi, Affilate này hiện chưa có tài khoản cá cược để rút tiền. Vui lòng liên hệ với quản lý của bạn.'
	WHEN 510 THEN N'Giá trị không hợp lệ! Giá trị phải nằm trong khoảng {MinAmount} đến {MaxAmount}'
	WHEN 511 THEN N'Gửi yêu cầu rút tiền không thành công. Vui lòng thử lại!'
	ELSE MessageContentVN END
WHERE MessageId IN (505,506,507,508,510,511)
GO

INSERT INTO dbo.LogType (TypeId, TypeName, Description)
SELECT
	TypeId
	,CASE TypeName
			WHEN '12BetDomain' THEN 'LicenseeDomain'
			WHEN 'AffDomainControl' THEN 'DomainControl'
			ELSE TypeName END AS TypeName
	,CASE Description
			WHEN '12BetDomain' THEN 'LicenseeDomain'
			WHEN 'AffDomainControl' THEN 'DomainControl'
			ELSE Description END AS Description
FROM Affiliate_12BET.dbo.LogType WITH (NOLOCK)
GO

INSERT INTO dbo.LogType (TypeId, TypeName, Description)
VALUES (27, 'Text', 'Text')
GO

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName)
SELECT 1, 1, 'Aff_Admin_CommGroup_Assign' UNION ALL
SELECT 2, 1, 'Aff_Admin_CommGroup_Del' UNION ALL
SELECT 3, 1, 'Aff_Admin_CommGroup_Ins' UNION ALL
SELECT 4, 1, 'Aff_Admin_CommGroup_Upd' UNION ALL
SELECT 5, 2, 'Aff_User_UserInfoUpd' UNION ALL
SELECT 6, 2, 'Aff_User_Affiliate_Ins' UNION ALL
SELECT 7, 3, 'Aff_Admin_AffiliateAdjustment_Ins' UNION ALL
SELECT 8, 4, 'Aff_User_PaymentRequest_Ins' UNION ALL
SELECT 9, 4, 'Aff_User_PaymentRequest_Upd' UNION ALL
SELECT 10, 4, 'Aff_Admin_AffiliatePaymentRequest_Upd' UNION ALL
SELECT 11, 7, 'Aff_Admin_Banner_Del' UNION ALL
SELECT 12, 7, 'Aff_Admin_Banner_Ins' UNION ALL
SELECT 13, 7, 'Aff_Admin_Banner_Upd' UNION ALL
SELECT 14, 8, 'Aff_EmailHistoryIns' UNION ALL
SELECT 15, 8, 'Aff_Admin_EmailHistory_Del' UNION ALL
SELECT 16, 9, 'Aff_Admin_Message_Del' UNION ALL
SELECT 17, 9, 'Aff_Admin_Message_Ins' UNION ALL
SELECT 18, 9, 'Aff_Admin_Message_Upd' UNION ALL
SELECT 19, 12, 'Aff_Admin_Login' UNION ALL
SELECT 20, 13, 'Aff_User_Login_ResultUpd' UNION ALL
SELECT 21, 16, 'Aff_User_ForgotPassword' UNION ALL
SELECT 22, 16, 'Aff_User_RecoverPassWord' UNION ALL
SELECT 23, 16, 'Aff_User_VerificationUpd' UNION ALL
SELECT 24, 16, 'Aff_Admin_Affiliate_Password_Upd' UNION ALL
SELECT 25, 16, 'Aff_Admin_ChangePassword' UNION ALL
SELECT 26, 21, 'Aff_Admin_LicenseeDomain_Del' UNION ALL
SELECT 27, 21, 'Aff_Admin_LicenseeDomain_Ins' UNION ALL
SELECT 28, 21, 'Aff_Admin_LicenseeDomain_Upd' UNION ALL
SELECT 29, 22, 'Aff_Admin_AffiliateDomain_Del' UNION ALL
SELECT 30, 22, 'Aff_Admin_AffiliateDomain_Ins' UNION ALL
SELECT 31, 22, 'Aff_Admin_AffiliateDomain_Upd' UNION ALL
SELECT 32, 23, 'Aff_Admin_DomainControl_Del' UNION ALL
SELECT 33, 23, 'Aff_Admin_DomainControl_Ins' UNION ALL
SELECT 34, 23, 'Aff_Admin_DomainControl_Upd' UNION ALL
SELECT 35, 24, 'Aff_Admin_AffiliateNote_Ins' UNION ALL
SELECT 36, 24, 'Aff_Admin_AffiliateNote_Upd' UNION ALL
SELECT 37, 25, 'Aff_Admin_AffiliateAffType_Upd' UNION ALL
SELECT 38, 25, 'Aff_Admin_AffiliateClosed_Upd' UNION ALL
SELECT 39, 25, 'Aff_Admin_AffiliateInfo_Upd' UNION ALL
SELECT 40, 25, 'Aff_Admin_AffiliatePreferredLanguage_Upd' UNION ALL
SELECT 41, 25, 'Aff_Admin_AffiliateStatus_Upd' UNION ALL
SELECT 42, 25, 'Aff_Admin_Affiliate_Approved' UNION ALL
SELECT 43, 25, 'Aff_Admin_Affiliate_Favorite_Upd' UNION ALL
SELECT 44, 26, 'Aff_Admin_LandingPage_Del' UNION ALL
SELECT 45, 26, 'Aff_Admin_LandingPage_Ins' UNION ALL
SELECT 46, 26, 'Aff_Admin_LandingPage_Upd' UNION ALL
SELECT 47, 27, 'Aff_Admin_Text_Del' UNION ALL
SELECT 48, 27, 'Aff_Admin_Text_Ins' UNION ALL
SELECT 49, 27, 'Aff_Admin_Text_Upd'
GO

UPDATE u WITH (ROWLOCK)
SET u.LogTypeId = l.ActionTypeId
	,u.LogActionId = l.ActionId
FROM dbo.UserLog_RunSP_Detail u
	INNER JOIN dbo.LogAction l WITH (NOLOCK) ON u.SPName = l.SPName
GO



/*===== Affiliate_N8B =====*/

USE Affiliate_N8B
GO

INSERT INTO dbo.Messages (MessageId, MessageTypeId, MessageContentEN)
SELECT 504, 3, N'Invalid Balance Account.' UNION ALL
SELECT 505, 3, N'Sorry, you do not have enough money to withdraw.' UNION ALL
SELECT 506, 3, N'Sorry, amount is invalid.' UNION ALL
SELECT 507, 3, N'Sorry, only Player Account method is supported. Please contact your Administrator.' UNION ALL
SELECT 508, 3, N'Sorry, this affiliate does not have Player Account. Please contact your Administrator.' UNION ALL
SELECT 509, 3, N'Sorry, this affiliate does not have Player Account.' UNION ALL
SELECT 510, 3, N'Invalid request amount! Amount must be between {MinAmount} and {MaxAmount}' UNION ALL
SELECT 511, 3, N'Insert transaction failed. Please try again!'
GO

UPDATE dbo.Messages WITH (ROWLOCK)
SET MessageContentVN = CASE MessageId
	WHEN 505 THEN N'Xin lỗi, số tiền trong tài khoản hiện không đủ.'
	WHEN 506 THEN N'Xin lỗi, giá trị không hợp lệ.'
	WHEN 507 THEN N'Xin lỗi, hệ thống chỉ hỗ trợ rút tiền thông qua tài khoản cá cược. Vui lòng liên hệ với quản lý của bạn.'
	WHEN 508 THEN N'Xin lỗi, Affilate này hiện chưa có tài khoản cá cược để rút tiền. Vui lòng liên hệ với quản lý của bạn.'
	WHEN 510 THEN N'Giá trị không hợp lệ! Giá trị phải nằm trong khoảng {MinAmount} đến {MaxAmount}'
	WHEN 511 THEN N'Gửi yêu cầu rút tiền không thành công. Vui lòng thử lại!'
	ELSE MessageContentVN END
WHERE MessageId IN (505,506,507,508,510,511)
GO

INSERT INTO dbo.LogType (TypeId, TypeName, Description)
SELECT
	TypeId
	,CASE TypeName
			WHEN '12BetDomain' THEN 'LicenseeDomain'
			WHEN 'AffDomainControl' THEN 'DomainControl'
			ELSE TypeName END AS TypeName
	,CASE Description
			WHEN '12BetDomain' THEN 'LicenseeDomain'
			WHEN 'AffDomainControl' THEN 'DomainControl'
			ELSE Description END AS Description
FROM Affiliate_12BET.dbo.LogType WITH (NOLOCK)
GO

INSERT INTO dbo.LogType (TypeId, TypeName, Description)
VALUES (27, 'Text', 'Text')
GO

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName)
SELECT 1, 1, 'Aff_Admin_CommGroup_Assign' UNION ALL
SELECT 2, 1, 'Aff_Admin_CommGroup_Del' UNION ALL
SELECT 3, 1, 'Aff_Admin_CommGroup_Ins' UNION ALL
SELECT 4, 1, 'Aff_Admin_CommGroup_Upd' UNION ALL
SELECT 5, 2, 'Aff_User_UserInfoUpd' UNION ALL
SELECT 6, 2, 'Aff_User_Affiliate_Ins' UNION ALL
SELECT 7, 3, 'Aff_Admin_AffiliateAdjustment_Ins' UNION ALL
SELECT 8, 4, 'Aff_User_PaymentRequest_Ins' UNION ALL
SELECT 9, 4, 'Aff_User_PaymentRequest_Upd' UNION ALL
SELECT 10, 4, 'Aff_Admin_AffiliatePaymentRequest_Upd' UNION ALL
SELECT 11, 7, 'Aff_Admin_Banner_Del' UNION ALL
SELECT 12, 7, 'Aff_Admin_Banner_Ins' UNION ALL
SELECT 13, 7, 'Aff_Admin_Banner_Upd' UNION ALL
SELECT 14, 8, 'Aff_EmailHistoryIns' UNION ALL
SELECT 15, 8, 'Aff_Admin_EmailHistory_Del' UNION ALL
SELECT 16, 9, 'Aff_Admin_Message_Del' UNION ALL
SELECT 17, 9, 'Aff_Admin_Message_Ins' UNION ALL
SELECT 18, 9, 'Aff_Admin_Message_Upd' UNION ALL
SELECT 19, 12, 'Aff_Admin_Login' UNION ALL
SELECT 20, 13, 'Aff_User_Login_ResultUpd' UNION ALL
SELECT 21, 16, 'Aff_User_ForgotPassword' UNION ALL
SELECT 22, 16, 'Aff_User_RecoverPassWord' UNION ALL
SELECT 23, 16, 'Aff_User_VerificationUpd' UNION ALL
SELECT 24, 16, 'Aff_Admin_Affiliate_Password_Upd' UNION ALL
SELECT 25, 16, 'Aff_Admin_ChangePassword' UNION ALL
SELECT 26, 21, 'Aff_Admin_LicenseeDomain_Del' UNION ALL
SELECT 27, 21, 'Aff_Admin_LicenseeDomain_Ins' UNION ALL
SELECT 28, 21, 'Aff_Admin_LicenseeDomain_Upd' UNION ALL
SELECT 29, 22, 'Aff_Admin_AffiliateDomain_Del' UNION ALL
SELECT 30, 22, 'Aff_Admin_AffiliateDomain_Ins' UNION ALL
SELECT 31, 22, 'Aff_Admin_AffiliateDomain_Upd' UNION ALL
SELECT 32, 23, 'Aff_Admin_DomainControl_Del' UNION ALL
SELECT 33, 23, 'Aff_Admin_DomainControl_Ins' UNION ALL
SELECT 34, 23, 'Aff_Admin_DomainControl_Upd' UNION ALL
SELECT 35, 24, 'Aff_Admin_AffiliateNote_Ins' UNION ALL
SELECT 36, 24, 'Aff_Admin_AffiliateNote_Upd' UNION ALL
SELECT 37, 25, 'Aff_Admin_AffiliateAffType_Upd' UNION ALL
SELECT 38, 25, 'Aff_Admin_AffiliateClosed_Upd' UNION ALL
SELECT 39, 25, 'Aff_Admin_AffiliateInfo_Upd' UNION ALL
SELECT 40, 25, 'Aff_Admin_AffiliatePreferredLanguage_Upd' UNION ALL
SELECT 41, 25, 'Aff_Admin_AffiliateStatus_Upd' UNION ALL
SELECT 42, 25, 'Aff_Admin_Affiliate_Approved' UNION ALL
SELECT 43, 25, 'Aff_Admin_Affiliate_Favorite_Upd' UNION ALL
SELECT 44, 26, 'Aff_Admin_LandingPage_Del' UNION ALL
SELECT 45, 26, 'Aff_Admin_LandingPage_Ins' UNION ALL
SELECT 46, 26, 'Aff_Admin_LandingPage_Upd' UNION ALL
SELECT 47, 27, 'Aff_Admin_Text_Del' UNION ALL
SELECT 48, 27, 'Aff_Admin_Text_Ins' UNION ALL
SELECT 49, 27, 'Aff_Admin_Text_Upd'
GO

UPDATE u WITH (ROWLOCK)
SET u.LogTypeId = l.ActionTypeId
	,u.LogActionId = l.ActionId
FROM dbo.UserLog_RunSP_Detail u
	INNER JOIN dbo.LogAction l WITH (NOLOCK) ON u.SPName = l.SPName
GO