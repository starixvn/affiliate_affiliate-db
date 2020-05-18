/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Upd]
	@TransID	BIGINT
	,@Status	VARCHAR(30) = NULL
	,@AdminDesc	NVARCHAR(300) = NULL
	,@AffDesc	NVARCHAR(300) = NULL
	,@UserID	INT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Affiliate - Payment Request - Update payment request by TransId

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #109008]
*/

BEGIN
	SET NOCOUNT ON

	IF @Status = 'Processing'
		SELECT @Status = 'Pending'

	DECLARE @SiteName VARCHAR(30)
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName')

	DECLARE @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustID		= @UserID
		,@FuncName	= '[Payment]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Update description only
	IF @Status IS NULL OR @Status = 'Pending'
	BEGIN
		IF ISNULL(@AdminDesc, '') = '' AND ISNULL(@AffDesc, '') = ''
			RETURN
	END
	ELSE IF @Status NOT IN ('Approved', 'Rejected')
	BEGIN
		-- Oops, You do not have permission to update this transaction.
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(502, @Language)
		RETURN
	END

	DECLARE @AffID					INT
			,@RefID					BIGINT
			,@AffUserName			NVARCHAR(50)
			,@Player_IBCCustID		INT
			,@Player_Username		NVARCHAR(50)
			,@Player_Currency		INT
			,@Player_CurrencyName	VARCHAR(50)
			,@Ballance_CustID		INT
			,@Ballance_UserName		NVARCHAR(50)
			,@AffPayout				MONEY
	
	SELECT	@AffID				= a.AffID
			,@RefID				= a.RefID
			,@Player_IBCCustID	= ap.IBCCustID
			,@Player_Currency	= ap.MemberCurrency
			,@AffPayout			= ap.AffPayout
	FROM dbo.AffTrans a WITH (NOLOCK)
		INNER JOIN dbo.AffPayout ap WITH (NOLOCK) ON a.RefID = ap.RefID
	WHERE a.TransID = @TransID AND a.TransType = 202 AND a.Status = 'Pending'

	IF @AffID IS NULL
	BEGIN
		-- This transaction is not a withdrawal.
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(501, @Language)
		RETURN
	END

	SELECT @AffUserName = username FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @AffID
	SELECT @Player_CurrencyName = currency FROM bodb02.dbo.Exchange WITH (NOLOCK) WHERE exchangeid = @Player_Currency
	SELECT @Ballance_UserName = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_BalPlayer' + @Player_CurrencyName
	SELECT @Ballance_CustID = custid FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE username = @Ballance_UserName

	IF @Ballance_CustID IS NULL
	BEGIN
		-- Invalid Balance Account.
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(504, @Language)
		RETURN
	END

	SELECT @Player_Username = c.username
	FROM dbo.AffDetail ad WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON @SiteName + '$' + ad.Player_Username = username2
	WHERE ad.AffID = @AffID

	IF @Player_Username IS NULL
	BEGIN
		-- This affiliate does not have Player Account.
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(509, @Language)
		RETURN
	END

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)
	SELECT  @OldData	= 'Status=' + ISNULL(Status, 'NULL')
							+ 'AdminDesc=' + ISNULL(AdminDesc, 'NULL')
							+ 'AffDesc=' + ISNULL(AffDesc, 'NULL')
			,@NewData	= 'Status=' + ISNULL(@Status, 'NULL')
							+ 'AdminDesc=' + ISNULL(@AdminDesc, 'NULL')
							+ 'AffDesc=' + ISNULL(@AffDesc, 'NULL')
			,@SPName	= OBJECT_NAME(@@PROCID)
	FROM dbo.AffPayout WITH (NOLOCK)
	WHERE AffID = @AffID AND RefID = @RefID
	
	IF @OldData = @NewData
		RETURN

	IF @Status = 'Approved'
	BEGIN
		EXEC DBTXN.bodb02.dbo.Aff_Admin_AffiliatePaymentRequest_Approve
			@RefID				= @RefID
			,@AffUserName		= @AffUserName
			,@Player_IBCCustID	= @Player_IBCCustID
			,@Player_Currency	= @Player_Currency
			,@Ballance_CustID	= @Ballance_CustID
			,@AffPayout			= @AffPayout
			,@UserID			= @UserID
			,@IP				= @IP
			,@ErrCode			= @ErrCode OUTPUT
			,@ErrMsg			= @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN
	END

	DECLARE @CompletedDate DATETIME
	SELECT  @CompletedDate = GETDATE()

	BEGIN TRY
		UPDATE dbo.AffPayout WITH (ROWLOCK)
		SET Status			= ISNULL(@Status, Status)
			,CompletedDate	= CASE WHEN @Status IS NOT NULL THEN @CompletedDate ELSE CompletedDate END
			,AdminDesc		= ISNULL(@AdminDesc, AdminDesc)
			,AffDesc		= ISNULL(@AffDesc, AffDesc)
		WHERE AffID = @AffID AND RefID = @RefID

		IF @Status IS NOT NULL
		BEGIN
			UPDATE dbo.AffTrans WITH (ROWLOCK)
			SET Status			= @Status
				,CompletedDate	= @CompletedDate
				,Creator		= @UserID
			WHERE TransID = @TransID
		END
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write Log
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffID,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO