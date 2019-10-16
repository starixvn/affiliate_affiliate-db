/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Exchange_Upd]
	@UserId			INT
	,@ExchangeId	INT
	,@Rate			FLOAT
	,@RateType		TINYINT
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Exchange Rate - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]

	Param Explanation:
		- @RateType:
			0: Selling Rate (Actual Rate)
			1: Buying Rate (Buying Rate)
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentDate SMALLDATETIME
	SELECT  @CurrentDate = CONVERT(DATE, GETDATE())

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[AffEx.Rate]'
		,@System	= 'AFFILIATE'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF @ExchangeId = 3
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'You cannot edit rate of USD.'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = 'ExchangeId=' + ISNULL(CONVERT(VARCHAR(5), ExchangeId), '')
					+ ',' + 'ActualRate2=' + ISNULL(CONVERT(VARCHAR(20), ActualRate2), '')
					+ ',' + 'BuyingRate2=' + ISNULL(CONVERT(VARCHAR(20), BuyingRate2), '')
	FROM dbo.Exchange_Current WITH (NOLOCK)
	WHERE ExchangeId = @ExchangeId

	IF @OldData IS NULL
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Exchange does not exists.'
		RETURN
	END

	IF EXISTS (
		SELECT 1 FROM dbo.Exchange_Current WITH (NOLOCK)
		WHERE ExchangeId = @ExchangeId
			AND
			(
				(@RateType = 0 AND ActualRate2 = @Rate)
				OR (@RateType = 1 AND BuyingRate2 = @Rate)
			)
	)
		RETURN -- no change

	-- Update process
	BEGIN TRY
		IF @ExchangeId = 2 -- Update RM --> update all exchanges
		BEGIN
			DECLARE @RateUS FLOAT
			SELECT  @RateUS = CASE WHEN @Rate = 0 THEN 0 ELSE 1.0/@Rate END

			UPDATE dbo.Exchange_Current WITH (ROWLOCK)
			SET ActualRate2 = CASE WHEN @RateType = 0 AND ExchangeId = @ExchangeId THEN @Rate ELSE Actualrate2 END
				,ActualRate = CASE WHEN @RateType = 0 AND ExchangeId <> @ExchangeId THEN @RateUS * ActualRate2 ELSE ActualRate END
				,BuyingRate2 = CASE WHEN @RateType = 1 AND ExchangeId = @ExchangeId THEN @Rate ELSE BuyingRate2 END
				,BuyingRate = CASE WHEN @RateType = 1 AND ExchangeId <> @ExchangeId THEN @RateUS * BuyingRate2 ELSE BuyingRate END

			-- Update Exchange table
			IF EXISTS (SELECT 1 FROM dbo.Exchange WITH (NOLOCK) WHERE UpdatedTime = @CurrentDate)
				DELETE dbo.Exchange WITH (ROWLOCK, UPDLOCK) WHERE UpdatedTime = @CurrentDate

			INSERT INTO dbo.Exchange
			(
				UpdatedTime,ExchangeID,Currency,ActualRate,ActualRate2,BuyingRate,BuyingRate2,Creator,DepositPercent,WithdrawalPercent
			)
			SELECT
				@CurrentDate,ExchangeID,Currency,ActualRate,ActualRate2,BuyingRate,BuyingRate2,@UserId,DepositPercent,WithdrawalPercent
			FROM dbo.Exchange_Current WITH (NOLOCK)
		END
		ELSE
		BEGIN
			UPDATE dbo.Exchange_Current WITH (ROWLOCK)
			SET ActualRate2 = CASE WHEN @RateType = 0 THEN @Rate ELSE Actualrate2 END
				,BuyingRate2 = CASE WHEN @RateType = 1 THEN @Rate ELSE BuyingRate2 END
			WHERE ExchangeId = @ExchangeId

			-- Update Exchange table
			IF EXISTS (SELECT 1 FROM dbo.Exchange WITH (NOLOCK) WHERE UpdatedTime = @CurrentDate AND ExchangeId = @ExchangeId)
				DELETE dbo.Exchange WITH (ROWLOCK, UPDLOCK) WHERE UpdatedTime = @CurrentDate AND ExchangeId = @ExchangeId

			INSERT INTO dbo.Exchange
			(
				UpdatedTime,ExchangeID,Currency,ActualRate,ActualRate2,BuyingRate,BuyingRate2,Creator,DepositPercent,WithdrawalPercent
			)
			SELECT
				@CurrentDate,ExchangeID,Currency,ActualRate,ActualRate2,BuyingRate,BuyingRate2,@UserId,DepositPercent,WithdrawalPercent
			FROM dbo.Exchange_Current WITH (NOLOCK)
			WHERE ExchangeId = @ExchangeId
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Update exchange rate is unsuccessful.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = 'ExchangeId=' + ISNULL(CONVERT(VARCHAR(5), ExchangeId), '')
					+ ',' + 'ActualRate2=' + ISNULL(CONVERT(VARCHAR(20), ActualRate2), '')
					+ ',' + 'BuyingRate2=' + ISNULL(CONVERT(VARCHAR(20), BuyingRate2), '')
	FROM dbo.Exchange_Current WITH (NOLOCK)
	WHERE ExchangeId = @ExchangeId

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
END
GO