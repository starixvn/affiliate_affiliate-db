/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_AdjustmentIns]  
	@LicenseeID		INT
	,@Amount		MONEY
	,@AffID			INT
	,@AdminID 		INT
	,@AdminUserName VARCHAR(50)
	,@AdminDesc 	NVARCHAR(300) = ''
	,@AffDesc 		NVARCHAR(300) = ''
	,@ip			NVARCHAR(15) = ''
	,@Language 		VARCHAR(5) = 'en-US'
	,@ErrCode 		INT = 0 OUTPUT
AS

/*  
	Creator: Vinh  
	Date: 2009-07-30  
	Task: Approve a payment request.
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet

	Revisions: 
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180208@Alex  : Support Liecnsee admin portal #90545
		- 20240606@Eddie: Enhance Adjustment Function with description for user's view [RedmineId : #205432]
*/

BEGIN
	SET NOCOUNT ON

	IF @Amount = 0
	BEGIN
		SELECT @ErrCode = 1011
		RETURN
	END

	IF(NOT EXISTS(SELECT 1 FROM AffInfo WITH (NOLOCK) WHERE AffID = @AffID ))
	BEGIN
		SELECT @ErrCode = 1006
		RETURN
	END

	DECLARE @AffCurrency VARCHAR(5), @AffCurrencyCode VARCHAR(5), @SysCurrency VARCHAR(5), @SysExRate FLOAT, @Status VARCHAR(30), @IsClosed BIT, @MaxAmount MONEY

	SELECT @AffCurrency = b.Currency,  @Status = Status, @IsClosed = IsClosed, @AffCurrencyCode = e.Code
	FROM AffInfo b WITH (NOLOCK)
		INNER JOIN Exchange e WITH (NOLOCK) ON e.ExchangeId=b.currency
	WHERE AffID = @AffID

	SET @MaxAmount = (SELECT SValue FROM SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_MaximumAdjustment' + @AffCurrencyCode)

	--Check Data 
	IF (@AffCurrency IS NULL OR ABS(@Amount) > @MaxAmount)
	BEGIN
		SELECT @ErrCode = 1011
		RETURN
	END

	IF @Status <> 'Approved'
	BEGIN
		SELECT @ErrCode = 1013
		RETURN
	END

	IF @IsClosed = 1
	BEGIN
		SELECT @ErrCode = 1014
		RETURN
	END

	DECLARE @CurrentDate DATETIME
	SET @CurrentDate = CURRENT_TIMESTAMP

	SELECT @SysCurrency = dbo.Aff_GetSystemCurrencyID()
	SELECT @SysExRate = dbo.Aff_GetExchangeRate(@AffCurrency, @SysCurrency, DEFAULT)

	INSERT INTO AffTrans
	(
		[AffID]
		,[TransDate]
		,[CompletedDate]
		,[Amount]
		,[Status]
		,[Description]
		,[AffDescription]
		,[Creator]
		,[AffCurrency]
		,[SysCurrency]
		,[SysExRate]
		,[TransType]
		,[RefID]
		,[AdminUserName]
	)
	VALUES
	(  
		@AffID
		,@CurrentDate
		,@CurrentDate
		,@Amount
		,'Completed'
		,@AdminDesc
		,@AffDesc
		,@AdminID
		,@AffCurrency
		,@SysCurrency
		,@SysExRate
		,203 --Adjustment TransType  
		,0
		,@AdminUserName
	)
	
	IF @@ERROR <> 0  
	BEGIN  
		SELECT @ErrCode = 1005   
		RETURN  
	END      

	 -- Recalculate BF in AffInfo table  
	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET BF = dbo.Aff_GetAffBalance(AffID)  
	WHERE AffID = @AffID 
 
	--Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)   
	SELECT @SPName = OBJECT_NAME(@@PROCID)  
	SELECT @Detail = 'Modify Balance Brought Forward. Amount = ' + dbo.Aff_ToString(@Amount)   
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @AdminID,  
		@AffID = @AffID,  
		@Typename = 'Adjustment', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP
END
GO