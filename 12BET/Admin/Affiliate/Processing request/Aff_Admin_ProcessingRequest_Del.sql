/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_ProcessingRequest_Del
	@RequestId	 INT
	,@UserId	 INT
	,@IP		 VARCHAR(50) = ''
	,@Language	 VARCHAR(50) = 'en-US'
	,@ErrCode	 INT = 0 OUTPUT
	,@ErrMsg	 NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created: 20210817@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Affiliate - Processing Request - delete processing request
	Revisions:
		- 20210817@Malcolm: Initialize SP [RedmineID: #159570]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @OldData NVARCHAR(MAX) = '', @SPName VARCHAR(200) = '', @AffId INT

	DECLARE @DeleteData TABLE
	(
		RequestId				INT 
		,AffId					INT
		,Creator				INT
		,CreationDate			SMALLDATETIME
		,LastModified			SMALLDATETIME
		,SubmittedDate			SMALLDATETIME
		,Deadline				SMALLDATETIME
		,Approver				INT
		,ApprovalDate			SMALLDATETIME
		,Status					VARCHAR(30)
		,MarketID				NVARCHAR(10)
		,PreferredPayment		VARCHAR(20) --Play for 12bet play, bank for Wire
		,Player_Username		VARCHAR(100)
		,PromotionMethod		NVARCHAR(1000)
		,WebRank				NVARCHAR(1000)
		,WebRegDate				NVARCHAR(1000)
		,WebSMLanguage			NVARCHAR(1000)
		,ServerCountry			NVARCHAR(1000)
		,WebSMQuality			NVARCHAR(1000)
		,WebSMType				NVARCHAR(1000)
		,WebAdvAff				NVARCHAR(1000)
		,TargetMarket			NVARCHAR(1000)
		,AgentName				NVARCHAR(1000)
		,ContactModeTime		NVARCHAR(1000)
		,Remark					NVARCHAR(1000)
		,BankName				NVARCHAR(100)
		,BankAddress			NVARCHAR(200)
		,SwiftCode				NVARCHAR(50)
		,AccountName			NVARCHAR(100)
		,AccountNo				VARCHAR(100)
	)

	DELETE dbo.ProcessingRequest WITH(ROWLOCK, UPDLOCK)
	OUTPUT 
		deleted.RequestId				
		,deleted.AffId					
		,deleted.Creator			
		,deleted.CreationDate			
		,deleted.LastModified			
		,deleted.SubmittedDate			
		,deleted.Deadline				
		,deleted.Approver				
		,deleted.ApprovalDate			
		,deleted.Status					
		,deleted.MarketID				
		,deleted.PreferredPayment		
		,deleted.Player_Username		
		,deleted.PromotionMethod		
		,deleted.WebRank			
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
	INTO @DeleteData
	(
		RequestId			
		,AffId					
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
		,BankName			
		,BankAddress		
		,SwiftCode			
		,AccountName		
		,AccountNo			
	)
	WHERE RequestId = @RequestId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'This request does not exist. Please check again!'
		RETURN
	END
	
	SELECT @AffId = AffId FROM @DeleteData

	-- Write Log
	
	SELECT @OldData = CONVERT(NVARCHAR(MAX), 
					  (
							SELECT 
								d.RequestId						AS '@RequestId'			
								,d.Creator						AS '@Creator'	
								,c.UserName						AS '@CreatedBy'
								,d.CreationDate					AS '@CreationDate'	
								,d.LastModified					AS '@LastModified'	
								,d.SubmittedDate				AS '@SubmittedDate'	
								,d.Deadline						AS '@Deadline'		
								,d.Approver						AS '@Approver'	
								,a.UserName						AS '@ApprovedBy'
								,d.ApprovalDate					AS '@ApprovalDate'	
								,d.Status						AS '@Status'
								,d.MarketID						AS '@MarketID'
								,ISNULL(m.MarketName, '')	    AS '@MarketName'		
								,d.PreferredPayment				AS '@PreferredPayment'
								,d.Player_Username				AS '@Player_Username'
								,d.PromotionMethod				AS '@PromotionMethod'
								,d.WebRank						AS '@WebsiteRank'		
								,d.WebRegDate					AS '@WebRegDate'	
								,d.WebSMLanguage				AS '@WebSMLanguage'	
								,d.ServerCountry				AS '@ServerCountry'	
								,d.WebSMQuality					AS '@WebSMQuality'	
								,d.WebSMType					AS '@WebSMType'		
								,d.WebAdvAff					AS '@WebAdvAff'		
								,d.TargetMarket					AS '@TargetMarket'	
								,d.AgentName					AS '@AgentName'		
								,d.ContactModeTime				AS '@ContactMode'
								,d.Remark						AS '@Remark'			
								,d.BankName						AS '@BankName'		
								,d.BankAddress					AS '@BankAddress'	
								,d.SwiftCode					AS '@SwiftCode'		
								,d.AccountName					AS '@AccountName'	
								,d.AccountNo					AS '@AccountNo'		
							FROM @DeleteData d
								LEFT JOIN dbo.Market m WITH(NOLOCK) ON m.MarketID = d.MarketID
								LEFT JOIN dbo.Users c WITH(NOLOCK) ON c.CustId = d.Creator
								LEFT JOIN dbo.Users a WITH(NOLOCK) ON a.CustId = d.Approver
							FOR XML PATH ('row'), ROOT ('root')
					))

	SELECT @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= '',
		@IP			= @IP,
		@Language	= @Language

END
GO