/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20200514@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Some new changes
		1. Limit max sub-affiliate level
		2. Change text 'Commission' to 'Revenue'
		3. Remove Exchange Setting (hide before)
*/
USE Affiliate_N88
GO

-- 1. Limit max sub-affiliate level
	-- Add setting
	INSERT INTO dbo.SystemSettings (SName, SValue)
	VALUES ('MaxSubLevel', '4')

	-- Add error message
	INSERT INTO dbo.Messages(MessageId,MessageTypeId,Description,MessageContentEN,MessageContentVN)
	VALUES (105, 1, N'Invalid Parent Aff ID / Max Sub Aff Level', N'The information you have entered is invalid. Please check again.', N'Thông tin bạn đã nhập không hợp lệ. Vui lòng kiểm tra lại.')

	UPDATE dbo.Messages WITH (ROWLOCK)
	SET MessageContentCS = MessageContentEN,
		MessageContentCH = MessageContentEN,
		MessageContentID = MessageContentEN,
		MessageContentTH = MessageContentEN,
		MessageContentKO = MessageContentEN,
		MessageContentES = MessageContentEN,
		MessageContentJP = MessageContentEN,
		MessageContentHIEN = MessageContentEN,
		MessageContentENEURO = MessageContentEN
	WHERE MessageId = 105


-- 2. Change text 'Commission' to 'Revenue'
	UPDATE dbo.CommGroup WITH (ROWLOCK)
	SET Description = 'Default System Revenue Group'
	WHERE GroupId = 1

	UPDATE dbo.CommGroup WITH (ROWLOCK)
	SET GroupName = ' No Revenue Share'
		,Description = 'Group for all zero revenue share/closed affiliates'
	WHERE GroupId = 2
	GO

-- 3. Remove Exchange Setting (hide before)
	DELETE dbo.Deductions WITH (ROWLOCK, UPDLOCK)
	WHERE DeductionId IN (13, 14)

	DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
	WHERE DeductionId IN (13, 14)

	DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
	WHERE DeductionId IN (13, 14)