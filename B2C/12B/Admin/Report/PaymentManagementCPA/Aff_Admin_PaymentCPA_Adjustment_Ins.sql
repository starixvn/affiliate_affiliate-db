/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_PaymentCPA_Adjustment_Ins]
	@AffID			INT
	,@UserID		INT
	,@PaymentID 	INT
	,@NewAmount		MONEY
	,@AdjustAmount	MONEY
	,@Transdesc		NVARCHAR(300) = ''
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created: 20251003@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Report - PaymentCPA - Adjustment

	Revisions:
		- 20251003@Lewis: Initialize SP [RedmineID: #240525]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @currentDate SMALLDATETIME
		,@WinlostDate	 SMALLDATETIME -- GMT+8
		,@TimeZone		 SMALLINT
        ,@Transtype      INT = 208 -- Adjustment for CPA

	SELECT  @TimeZone	 = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'
	SELECT  @WinlostDate = CAST(DATEADD(HOUR, 4 + @TimeZone, GETDATE()) AS SMALLDATETIME)

	SELECT  @currentDate = CONVERT(DATE, GETDATE())

	DECLARE @Language NVARCHAR(5) = 'en-US'

    DECLARE @StartSchedule DATE
            ,@EndSchedule DATE
    SELECT  @StartSchedule = StartSchedule
            ,@EndSchedule = EndSchedule
	FROM dbo.rptAffiliateCPA WITH (NOLOCK)
	WHERE ID = @PaymentID

	-- Check permisison
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[Payment]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @AffCurrency	INT
			,@AffRate		FLOAT
			,@Status		VARCHAR(30)

	SELECT	@AffCurrency	= ai.Currency
			,@AffRate		= e.Rate
			,@Status		= ai.Status
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

    IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.rptAffiliateCPA WHERE ID = @PaymentID AND Status IN ('Qualified','Not Qualified'))
	BEGIN
		-- This payment schedule is invalid!
		SELECT @ErrCode = 105, @ErrMsg = N'This payment schedule is invalid!'
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.AffTrans (AffID,TransDate,CompletedDate,Amount,Status,Description,Creator,TransType,AffCurrency,AffRate,WinlostDate)
			VALUES (@AffID, @WinlostDate, GETDATE(),@AdjustAmount,'Approved',@Transdesc + ' - Schedule ' + CONVERT(VARCHAR(10), @StartSchedule, 101) + '-' + CONVERT(VARCHAR(10), @EndSchedule, 101),@UserID,@Transtype,@AffCurrency,@AffRate, CAST(@WinlostDate AS DATE))
        
        UPDATE dbo.rptAffiliateCPA WITH (ROWLOCK, UPDLOCK)
        SET AdjustedAmount = @NewAmount
            ,AdjustedDate = CAST(@WinlostDate AS DATE)
            ,Description = @Transdesc
            ,AdjustedBy = @UserID
			,UpdatedDate = @WinlostDate
        WHERE ID = @PaymentID
	END TRY
	BEGIN CATCH
		-- This transaction is unsuccessful.
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(1303, @Language)
		RETURN
	END CATCH

	-- Write Log
	DECLARE @LogData NVARCHAR(MAX), @SPName VARCHAR(50)
	SELECT  @LogData = 'AdjustAmount=' + CONVERT(VARCHAR(50), @AdjustAmount) 
						+ ', NewAmount=' + CONVERT(VARCHAR(50), @NewAmount)
						+ ', Description=' + CONVERT(NVARCHAR(300), @Transdesc)
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