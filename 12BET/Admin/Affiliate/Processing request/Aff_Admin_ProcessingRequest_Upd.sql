/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_ProcessingRequest_Upd
	@RequestId				INT
	,@UserId				INT
	,@Deadline				SMALLDATETIME
	,@Status				VARCHAR(30)
	,@MarketID				NVARCHAR(10)
	,@PreferredPayment		VARCHAR(20) --Play for 12bet play, bank for Wire
	,@Player_Username		VARCHAR(100)
	,@PromotionMethod		NVARCHAR(1000)
	,@Webrank				NVARCHAR(1000)
	,@WebRegDate			NVARCHAR(1000)
	,@WebSMLanguage			NVARCHAR(1000)
	,@ServerCountry			NVARCHAR(1000)
	,@WebSMQuality			NVARCHAR(1000)
	,@WebSMType				NVARCHAR(1000)
	,@WebAdvAff				NVARCHAR(1000)
	,@TargetMarket			NVARCHAR(1000)
	,@AgentName				NVARCHAR(1000)
	,@ContactModeTime		NVARCHAR(1000)
	,@Remark				NVARCHAR(1000)
	,@BankName				NVARCHAR(100)
	,@BankAddress			NVARCHAR(200)
	,@BankSwiftCode			NVARCHAR(50)
	,@BankAccountName		NVARCHAR(100)
	,@BankAccountNo			VARCHAR(100)
	,@Language				VARCHAR(10) = 'en-US'
	,@IP					VARCHAR(50) = ''
	,@ErrCode				INT = 0 OUTPUT
	,@ErrMsg				NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created: 20210817@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Affiliate - Processing Request - Update processing request
	Revisions:
		- 20210817@Malcolm: Initialize SP [RedmineID: #159570]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT = 0, @NewData NVARCHAR(MAX) = '', @OldData NVARCHAR(MAX) = '', @SPName VARCHAR(200) = ''

	SELECT @AffId = AffId FROM dbo.ProcessingRequest pr WITH(NOLOCK) WHERE RequestId = @RequestId

	IF @Deadline < GETDATE()
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid deadline.'
		RETURN
	END

	DECLARE @updateData TABLE
	(
		--Insert
		Deadline_Ins				SMALLDATETIME
		,Status_Ins					VARCHAR(30)
		,MarketID_Ins				NVARCHAR(10)
		,PreferredPayment_Ins		VARCHAR(20) --Play for 12bet play, bank for Wire
		,Player_Username_Ins		VARCHAR(100)
		,PromotionMethod_Ins		NVARCHAR(1000)
		,Webrank_Ins				NVARCHAR(1000)
		,WebRegDate_Ins				NVARCHAR(1000)
		,WebSMLanguage_Ins			NVARCHAR(1000)
		,ServerCountry_Ins			NVARCHAR(1000)
		,WebSMQuality_Ins			NVARCHAR(1000)
		,WebSMType_Ins				NVARCHAR(1000)
		,WebAdvAff_Ins				NVARCHAR(1000)
		,TargetMarket_Ins			NVARCHAR(1000)
		,AgentName_Ins				NVARCHAR(1000)
		,ContactbleMode_Ins			NVARCHAR(1000)
		,Remark_Ins					NVARCHAR(1000)
		,BankName_Ins				NVARCHAR(100)
		,BankAddress_Ins			NVARCHAR(200)
		,SwiftCode_Ins				NVARCHAR(50)
		,AccountName_Ins			NVARCHAR(100)
		,AccountNo_Ins				VARCHAR(100)
		,LastModified_Ins			SMALLDATETIME
		,Approver_Ins				INT
		,ApprovalDate_Ins			SMALLDATETIME
		---Delete
		,Deadline_Del				SMALLDATETIME
		,Status_Del					VARCHAR(30)
		,MarketID_Del				NVARCHAR(10)
		,PreferredPayment_Del		VARCHAR(20) --Play for 12bet play, bank for Wire
		,Player_Username_Del		VARCHAR(100)
		,PromotionMethod_Del		NVARCHAR(1000)
		,Webrank_Del				NVARCHAR(1000)
		,WebRegDate_Del				NVARCHAR(1000)
		,WebSMLanguage_Del			NVARCHAR(1000)
		,ServerCountry_Del			NVARCHAR(1000)
		,WebSMQuality_Del			NVARCHAR(1000)
		,WebSMType_Del				NVARCHAR(1000)
		,WebAdvAff_Del				NVARCHAR(1000)
		,TargetMarket_Del			NVARCHAR(1000)
		,AgentName_Del				NVARCHAR(1000)
		,ContactbleMode_Del			NVARCHAR(1000)
		,Remark_Del					NVARCHAR(1000)
		,BankName_Del				NVARCHAR(100)
		,BankAddress_Del			NVARCHAR(200)
		,SwiftCode_Del				NVARCHAR(50)
		,AccountName_Del			NVARCHAR(100)
		,AccountNo_Del				VARCHAR(100)
		,LastModified_Del			SMALLDATETIME
		,Approver_Del				INT
		,ApprovalDate_Del			SMALLDATETIME
	)

	UPDATE dbo.ProcessingRequest WITH(ROWLOCK)
		SET Deadline				= @Deadline
			,Status					= @Status
			,MarketID				= @MarketID
			,PreferredPayment		= @PreferredPayment
			,Player_Username		= @Player_Username
			,PromotionMethod		= @PromotionMethod
			,Webrank				= @Webrank
		    ,WebRegDate				= @WebRegDate
			,WebSMLanguage			= @WebSMLanguage 
			,ServerCountry			= @ServerCountry
			,WebSMQuality			= @WebSMQuality
			,WebSMType				= @WebSMType
			,WebAdvAff				= @WebAdvAff
			,TargetMarket			= @TargetMarket
			,AgentName				= @AgentName
			,ContactModeTime		= @ContactModeTime
			,Remark					= @Remark
			,Wire_BankName			= @BankName
			,Wire_BankAddress		= @BankAddress
			,Wire_SwiftCode			= @BankSwiftCode
			,Wire_AccountName		= @BankAccountName
			,Wire_AccountNo			= @BankAccountNo
			,SubmittedDate			= CASE WHEN @Status = 'Submitted' THEN GETDATE() ELSE SubmittedDate END
			,LastModified			= CASE WHEN @Status IN ('Draft', 'Submitted')	THEN GETDATE() ELSE LastModified  END
			,ApprovalDate			= CASE WHEN @Status IN ('Approved', 'Rejected') THEN GETDATE() ELSE ApprovalDate  END
			,Approver				= CASE WHEN @Status IN ('Approved', 'Rejected') THEN @UserId   ELSE Approver	  END
	OUTPUT 
		--Insert
		inserted.Deadline			
		,inserted.Status					
		,inserted.MarketID				
		,inserted.PreferredPayment		
		,inserted.Player_Username		
		,inserted.PromotionMethod		
		,inserted.Webrank			
		,inserted.WebRegDate	
		,inserted.WebSMLanguage		
		,inserted.ServerCountry				
		,inserted.WebSMQuality			
		,inserted.WebSMType			
		,inserted.WebAdvAff				
		,inserted.TargetMarket			
		,inserted.AgentName				
		,inserted.ContactModeTime			
		,inserted.Remark					
		,inserted.Wire_BankName			
		,inserted.Wire_BankAddress		
		,inserted.Wire_SwiftCode			
		,inserted.Wire_AccountName		
		,inserted.Wire_AccountNo
		,inserted.LastModified		
		,inserted.Approver				
		,inserted.ApprovalDate			
		--delete
		,deleted.Deadline			
		,deleted.Status					
		,deleted.MarketID				
		,deleted.PreferredPayment		
		,deleted.Player_Username		
		,deleted.PromotionMethod		
		,deleted.Webrank			
		,deleted.WebRegDate	
		,deleted.WebSMLanguage		
		,deleted.ServerCountry				
		,deleted.WebSMQuality			
		,deleted.WebSMType			
		,deleted.WebAdvAff				
		,deleted.TargetMarket			
		,deleted.AgentName				
		,deleted.ContactModeTime			
		,deleted.Remark					
		,deleted.Wire_BankName			
		,deleted.Wire_BankAddress		
		,deleted.Wire_SwiftCode			
		,deleted.Wire_AccountName		
		,deleted.Wire_AccountNo	
		,deleted.LastModified		
		,deleted.Approver				
		,deleted.ApprovalDate
	INTO @updateData
	(
		--Insert
		Deadline_Ins				
		,Status_Ins					
		,MarketID_Ins				
		,PreferredPayment_Ins		
		,Player_Username_Ins		
		,PromotionMethod_Ins		
		,Webrank_Ins			
		,WebRegDate_Ins	
		,WebSMLanguage_Ins		
		,ServerCountry_Ins				
		,WebSMQuality_Ins			
		,WebSMType_Ins			
		,WebAdvAff_Ins				
		,TargetMarket_Ins			
		,AgentName_Ins				
		,ContactbleMode_Ins			
		,Remark_Ins					
		,BankName_Ins			
		,BankAddress_Ins		
		,SwiftCode_Ins			
		,AccountName_Ins		
		,AccountNo_Ins	
		,LastModified_Ins		
		,Approver_Ins				
		,ApprovalDate_Ins
		---Delete
		,Deadline_Del				
		,Status_Del					
		,MarketID_Del				
		,PreferredPayment_Del		
		,Player_Username_Del		
		,PromotionMethod_Del		
		,Webrank_Del			
		,WebRegDate_Del	
		,WebSMLanguage_Del		
		,ServerCountry_Del				
		,WebSMQuality_Del			
		,WebSMType_Del			
		,WebAdvAff_Del				
		,TargetMarket_Del			
		,AgentName_Del				
		,ContactbleMode_Del			
		,Remark_Del					
		,BankName_Del			
		,BankAddress_Del		
		,SwiftCode_Del			
		,AccountName_Del		
		,AccountNo_Del	
		,LastModified_Del	
		,Approver_Del			
		,ApprovalDate_Del
	)
	WHERE RequestId = @RequestId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This request does not exist. Please check again!'
		RETURN
	END
	--Write Log
	SELECT @OldData = CONVERT(NVARCHAR(MAX), 
					  (
								SELECT
									@RequestId                       AS '@RequestId'
									,u.Deadline_Del					 AS '@Deadline'			
									,u.Status_Del					 AS '@Status'				
									,u.MarketID_Del					 AS '@MarketID'	
									,ISNULL(m.MarketName, '')		 AS '@MarketName'		
									,u.PreferredPayment_Del			 AS '@PreferredPayment'
									,u.Player_Username_Del			 AS '@Player_Username'	
									,u.PromotionMethod_Del			 AS '@PromotionMethod'	
									,u.Webrank_Del					 AS '@WebsiteRank'			
									,u.WebRegDate_Del				 AS '@WebRegDate'	
									,u.WebSMLanguage_Del			 AS '@WebSMLanguage'		
									,u.ServerCountry_Del			 AS '@ServerCountry'		
									,u.WebSMQuality_Del				 AS '@WebSMQuality'		
									,u.WebSMType_Del				 AS '@WebSMType'			
									,u.WebAdvAff_Del				 AS '@WebAdvAff'			
									,u.TargetMarket_Del				 AS '@TargetMarket'		
									,u.AgentName_Del				 AS '@AgentName'			
									,u.ContactbleMode_Del			 AS '@ContactMode'		
									,u.Remark_Del					 AS '@Remark'				
									,u.BankName_Del					 AS '@BankName'			
									,u.BankAddress_Del				 AS '@BankAddress'		
									,u.SwiftCode_Del				 AS '@SwiftCode'			
									,u.AccountName_Del				 AS '@AccountName'		
									,u.AccountNo_Del				 AS '@AccountNo'	
								FROM @UpdateData u
									LEFT JOIN dbo.Market m WITH(NOLOCK) ON m.MarketId = u.MarketID_Del
								FOR XML PATH('row'), ROOT('root')
					  ))

	SELECT @NewData = CONVERT(NVARCHAR(MAX), 
					  (
								SELECT
									@RequestId                       AS '@RequestId'
									,u.Deadline_Ins					 AS '@Deadline'			
									,u.Status_Ins					 AS '@Status'				
									,u.MarketID_Ins					 AS '@MarketID'		
									,ISNULL(m.MarketName, '')		 AS '@MarketName'		
									,u.PreferredPayment_Ins			 AS '@PreferredPayment'
									,u.Player_Username_Ins			 AS '@Player_Username'	
									,u.PromotionMethod_Ins			 AS '@PromotionMethod'	
									,u.Webrank_Ins					 AS '@WebsiteRank'			
									,u.WebRegDate_Ins				 AS '@WebRegDate'	
									,u.WebSMLanguage_Ins			 AS '@WebSMLanguage'		
									,u.ServerCountry_Ins			 AS '@ServerCountry'		
									,u.WebSMQuality_Ins				 AS '@WebSMQuality'		
									,u.WebSMType_Ins				 AS '@WebSMType'			
									,u.WebAdvAff_Ins				 AS '@WebAdvAff'			
									,u.TargetMarket_Ins				 AS '@TargetMarket'		
									,u.AgentName_Ins				 AS '@AgentName'			
									,u.ContactbleMode_Ins			 AS '@ContactMode'		
									,u.Remark_Ins					 AS '@Remark'				
									,u.BankName_Ins					 AS '@BankName'			
									,u.BankAddress_Ins				 AS '@BankAddress'		
									,u.SwiftCode_Ins				 AS '@SwiftCode'			
									,u.AccountName_Ins				 AS '@AccountName'		
									,u.AccountNo_Ins				 AS '@AccountNo'	
								FROM @UpdateData u
									LEFT JOIN dbo.Market m WITH(NOLOCK) ON m.MarketId = u.MarketID_Ins
								FOR XML PATH('row'), ROOT('root')
					 ))

	SELECT @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
	
END
GO
