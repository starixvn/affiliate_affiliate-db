/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_ProcessingRequest_Ins
	 @Username				NVARCHAR(50)
	,@UserId				INT
	,@Deadline				DATETIME
	,@Status				VARCHAR(30)
	,@MarketID				NVARCHAR(10)	= ''
	,@PreferredPayment		VARCHAR(20)		= ''
	,@Player_Username		VARCHAR(100)	= ''
	,@PromotionMethod		NVARCHAR(1000)	= ''
	,@WebRank				NVARCHAR(1000)	= ''
	,@WebRegDate			NVARCHAR(1000)	= ''
	,@WebSMLanguage			NVARCHAR(1000)	= ''
	,@ServerCountry			NVARCHAR(1000)	= ''
	,@WebSMQuality			NVARCHAR(1000)	= ''
	,@WebSMType				NVARCHAR(1000)	= ''
	,@WebAdvAff				NVARCHAR(1000)	= ''
	,@TargetMarket			NVARCHAR(1000)	= ''
	,@AgentName				NVARCHAR(1000)
	,@ContactModeTime		NVARCHAR(1000)	= ''
	,@Remark				NVARCHAR(1000)	= ''
	,@BankName				NVARCHAR(100)	= ''
	,@BankAddress			NVARCHAR(200)	= ''
	,@BankSwiftCode			NVARCHAR(50)	= ''
	,@BankAccountName		NVARCHAR(100)	= ''
	,@BankAccountNo			VARCHAR(100)	= ''
	,@IP					VARCHAR(50)		= ''
	,@Language				VARCHAR(10)		= 'en-US'
	,@ErrCode				INT				= 0 OUTPUT
	,@ErrMsg				NVARCHAR(MAX)	= '' OUTPUT
AS

/*
	Created: 20210817@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Affiliate - Processing Request - Add processing request
	Revisions:
		- 20210817@Malcolm: Initialize SP [RedmineID: #159570]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT = 0, @SPName VARCHAR(200) = '', @NewData NVARCHAR(MAX), @MarketName NVARCHAR(50) = '', @RequestId INT, @PreferredLanguage VARCHAR(11)
	-- You are not authorized to process the selected affiliate.
	SELECT @AffId = AffId , @PreferredLanguage = PreferredLanguage FROM dbo.AffDetail ad WITH(NOLOCK) WHERE ad.UserName = @Username 	
	IF ISNULL(@AffId, 0) = 0
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid affiliate username.'
		RETURN
	END

	IF NOT EXISTS(SELECT MarketId FROM UserMarket m WITH(NOLOCK) WHERE m.CustId = @UserId AND m.MarketId = @PreferredLanguage) 
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'You are not authorized to process the selected affiliate.'
		RETURN
	END

	IF @Deadline < CONVERT(DATE, GETDATE())
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid deadline.'
		RETURN
	END

	INSERT INTO dbo.ProcessingRequest 
	(
		AffId
		,Creator
		,CreationDate
		,LastModified
		,SubmittedDate
		,Deadline
		,Approver
		,ApprovalDate
		,Status
		,MarketID
		,PreferredPayment
		,Player_Username
		,PromotionMethod
		,WebRank
		,WebRegDate
		,WebSMLanguage
		,ServerCountry
		,WebSMQuality
		,WebSMType
		,WebAdvAff
		,TargetMarket
		,AgentName
		,ContactModeTime
		,Remark
		,Wire_BankName
		,Wire_BankAddress
		,Wire_SwiftCode
		,Wire_AccountName
		,Wire_AccountNo
	)
	VALUES 
	(
		@AffId
		,@UserId 	-- CreatedBy
		,GETDATE() 	-- CreationDate
		,NULL 		-- LastModified
		,CASE WHEN @Status = 'Submitted' THEN GETDATE() ELSE NULL END -- SubmittedDate
		,@Deadline
		,NULL 		-- Approver
		,NULL 		-- ApprovalDate
		,@Status	-- Status
		,@MarketID
		,@PreferredPayment
		,@Player_Username
		,@PromotionMethod
		,@WebRank
		,@WebRegDate
		,@WebSMLanguage
		,@ServerCountry
		,@WebSMQuality
		,@WebSMType
		,@WebAdvAff
		,@TargetMarket
		,@AgentName
		,@ContactModeTime
		,@Remark
		,@BankName
		,@BankAddress
		,@BankSwiftCode
		,@BankAccountName
		,@BankAccountNo
	)
	
	SELECT @RequestId = SCOPE_IDENTITY()

    SELECT @MarketName = MarketName FROM dbo.Market WITH(NOLOCK) WHERE MarketID = @MarketID

	-- Write Log
	SELECT @SPName = OBJECT_NAME(@@PROCID)
	
	SELECT @NewData = CONVERT(NVARCHAR(MAX), 
					  (
							SELECT 
								@RequestId								AS '@RequestId'
								,CONVERT(VARCHAR(30),@Deadline, 120)	AS '@Deadline'
								,@Status								AS '@Status'
								,@MarketID								AS '@MarketID'
								,@MarketName							AS '@MarketName'
								,@PreferredPayment						AS '@PaymentMethod'
								,@Player_Username						AS '@Player_Username'
								,@PromotionMethod						AS '@PromotionMethod'
								,@WebRank								AS '@WebsiteRank'
								,@WebRegDate							AS '@WebRegDate'
								,@WebSMLanguage							AS '@WebSMLanguage'
								,@ServerCountry							AS '@ServerCountry'
								,@WebSMQuality							AS '@WebSMQuality'
								,@WebSMType								AS '@WebSMType'
								,@WebAdvAff								AS '@WebAdvAff'
								,@TargetMarket							AS '@TargetMarket'
								,@AgentName								AS '@AgentName'
								,@ContactModeTime						AS '@ContactMode'
								,@Remark								AS '@Remark'
								,@BankName								AS '@BankName'
								,@BankAddress							AS '@BankAddress'
								,@BankSwiftCode							AS '@BankSwiftCode'
								,@BankAccountName						AS '@BankAccountName'
								,@BankAccountNo							AS '@BankAccountNo'
							FOR XML PATH ('row'), ROOT ('root')
					  ))

	SELECT @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= '',
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO