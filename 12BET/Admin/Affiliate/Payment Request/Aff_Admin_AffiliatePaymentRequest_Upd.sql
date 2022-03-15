/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
	Created: 20160614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Payment Request - Update payment request by TransID

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20211222@Malcolm: Split transfer out of bettrans [RedmineID: #165095]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
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
			,@Ballance_CustID	INT
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
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON '12BET$' + ad.Player_Username = username2
	WHERE ad.AffID = @AffID

	IF @Player_Username IS NULL
	BEGIN
		-- This Payment is belonging Affilite. But 12Bet Username is different.
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(505, @Language)
		RETURN
	END

	-- For Log
	DECLARE @OldData NVARCHAR(4000), @NewData NVARCHAR(4000), @SPName VARCHAR(50)

	SELECT @OldData = CONVERT(NVARCHAR(MAX),
					  (
						 SELECT	Status AS '@Status', 
							    AdminDesc AS '@AdminDesc', 
							    AffDesc AS '@AffDesc' 
						 FROM dbo.AffPayout WITH (NOLOCK) 
						 WHERE AffID = @AffID AND RefID = @RefID 
						 FOR XML PATH ('row'), ROOT('root')
					  ))

	SELECT @NewData = CONVERT(NVARCHAR(MAX), 
					  (
							SELECT @Status AS '@Status', 
								   @AdminDesc AS '@AdminDesc', 
								   @AffDesc AS '@AffDesc' 
						    FOR XML PATH('row'), ROOT('root')
					  ))

	SELECT @SPName	= OBJECT_NAME(@@PROCID)

	IF @OldData = @NewData
		RETURN

	DECLARE @Tmp TABLE (Status NVARCHAR(50), CompletedDate DATETIME, AdminDesc NVARCHAR(300), AffDesc NVARCHAR(300), Creator INT, TypeId TINYINT)

	DECLARE @CompletedDate DATETIME
	SELECT  @CompletedDate = GETDATE()

	BEGIN TRY
		UPDATE dbo.AffPayout WITH (ROWLOCK)
		SET Status			= ISNULL(@Status, Status)
			,CompletedDate	= CASE WHEN @Status IS NOT NULL THEN @CompletedDate ELSE CompletedDate END
			,AdminDesc		= ISNULL(@AdminDesc, AdminDesc)
			,AffDesc		= ISNULL(@AffDesc, AffDesc)
		OUTPUT deleted.Status, deleted.CompletedDate, deleted.AdminDesc, deleted.AffDesc, 1
			INTO @Tmp (Status, CompletedDate, AdminDesc, AffDesc, TypeId)
		WHERE AffID = @AffID AND RefID = @RefID

		IF @Status IS NOT NULL
		BEGIN
			UPDATE dbo.AffTrans WITH (ROWLOCK)
			SET Status			= @Status
				,CompletedDate	= @CompletedDate
				,Creator		= @UserID
			OUTPUT deleted.Status, deleted.CompletedDate, deleted.Creator, 2
				INTO @Tmp (Status, CompletedDate, Creator, TypeId)
			WHERE TransID = @TransID
		END
	END TRY
	BEGIN CATCH
		IF EXISTS (SELECT 1 FROM @Tmp)
		BEGIN
			UPDATE p WITH (ROWLOCK)
				SET p.Status		= t.Status,
					p.CompletedDate = t.CompletedDate,
					p.AdminDesc		= t.AdminDesc,
					p.AffDesc		= t.AffDesc
			FROM dbo.AffPayout p
				CROSS JOIN @Tmp t 
			WHERE p.AffID = @AffID AND p.RefID = @RefID AND t.TypeId = 1
		END
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

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
		BEGIN
			UPDATE p WITH (ROWLOCK)
				SET p.Status		= t.Status,
					p.CompletedDate = t.CompletedDate,
					p.AdminDesc		= t.AdminDesc,
					p.AffDesc		= t.AffDesc
			FROM dbo.AffPayout p
				CROSS JOIN @Tmp t 
			WHERE p.AffID = @AffID AND p.RefID = @RefID AND t.TypeId = 1

			UPDATE at 
				SET at.Status			= t.Status,
					at.CompletedDate	= t.CompletedDate,
					at.Creator			= t.Creator
			FROM dbo.AffTrans at WITH(ROWLOCK)
				CROSS JOIN @Tmp t 
			WHERE TransID = @TransID AND t.TypeId = 2
			RETURN
		END
	END

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