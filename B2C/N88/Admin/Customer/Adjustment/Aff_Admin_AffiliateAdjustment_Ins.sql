/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateAdjustment_Ins]
	@AffID		INT
	,@UserID	INT
	,@Amount	MONEY
	,@Transdesc	NVARCHAR(300) = ''
	,@TransID	BIGINT = 0 OUTPUT
	,@IP		VARCHAR(20) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Customer - Adjustment - Insert adjustment amount

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20230522@Sally: Support Currency BDT, USD 72 [RedmineID: #188429]
		- 20250411@Sally: Enhance get BBF by TimeZone [RedmineID: #222401]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @currentDate SMALLDATETIME
		,@WinlostDate	 SMALLDATETIME -- GMT+8
		,@TimeZone		 SMALLINT

	SELECT  @TimeZone	 = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'
	SELECT  @WinlostDate = CAST(CONVERT(VARCHAR(10), DATEADD(HOUR, 4 + @TimeZone, GETDATE()), 120) AS SMALLDATETIME)

	SELECT  @currentDate = CONVERT(DATE, GETDATE())

	DECLARE @Language NVARCHAR(5) = 'en-US'

	SELECT @ErrCode = 0, @ErrMsg = '', @Amount = ISNULL(@Amount, 0)

	-- Check permisison
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[Payment]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF @Amount = 0
	BEGIN
		-- Sorry, amount is invalid.
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1301, @Language)
		RETURN
	END

	DECLARE @AffCurrency	INT
			,@AffRate		FLOAT
			,@Status		VARCHAR(30)

	SELECT	@AffCurrency	= ai.Currency
			,@AffRate		= e.Rate
			,@Status		= ai.STATUS
	FROM AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON ai.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@currentDate, ISNULL(t.ExchangeId, ai.Currency), 0) e
	WHERE ai.AffID = @AffID

	IF @@ROWCOUNT = 0
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
		RETURN
	END

	IF @Status <> 'Approved'
	BEGIN
		-- Sorry, You cannot do adjustment because this Affiliate is not approved yet.
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1302, @Language)
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.AffTrans (AffID,TransDate,CompletedDate,Amount,Status,Description,Creator,TransType,AffCurrency,AffRate,WinlostDate)
			VALUES (@AffID,GETDATE(),GETDATE(),@Amount,'Completed',@Transdesc,@UserID,203,@AffCurrency,@AffRate,@WinlostDate)
	END TRY
	BEGIN CATCH
		-- This transaction is unsuccessful.
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(1303, @Language)
		RETURN
	END CATCH

	-- Write Log
	DECLARE @LogData NVARCHAR(4000), @SPName VARCHAR(50)
	SELECT  @LogData = 'Amount=' + CONVERT(VARCHAR(50), @Amount)
			,@SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffID,
		@SPName		= @SPName,
		@OldData	= '',
		@NewData	= @LogData,
		@IP			= @IP,
		@Language	= @Language
END
GO