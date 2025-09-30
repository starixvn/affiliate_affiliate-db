ALTER PROC [dbo].[Aff_AdjustmentIns] 
	@Amount MONEY
	,@AffID INT
	,@AdminID INT
	,@transdesc NVARCHAR(300) = ''
	,@transid BIGINT OUTPUT
	,@ip NVARCHAR(15) = ''
	,@language VARCHAR(2) = 'E'
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	-- DB: DB052.Affiliate_12Bet
	/*
	Creator : Vinh
	Date : 2009-07-30
	Task : Approve a payment request.

	Input 
		0) @Amount Adjusment amount
		1) @AffId (For Double check) 
		2) @AdminID User insert transaction
		3) @transdesc Description of transaction
		4) @transid transid for this Adjustment
		5) @userid ID of Admin update this Adjustment
		6) @IP IP update Adjustment
	   Output
		1) @ErrCode:
			= 0: Transaction recorded successfully.
			> 0: Specific Error.
		2) @ErrMsg: Error description.

	Revisions:
		-20140424@Bobby: Support to enable adjustment and remove members for Closed/Locked affiliates. Support at https://redmine.nexcel.vn/issues/15409
*/
	BEGIN
		SET NOCOUNT ON

		--SELECT @ErrCode = 101, @ErrMsg = 'do it later..'
		EXEC [dbo].[Aff_Con_CheckPermission] @custid = @AdminID
			,@funcname = '[Payment]'
			,--User the same with payment
			@System = 'AFFILIATE'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0 RETURN

		IF @Amount = 0
		BEGIN
			SELECT @ErrMsg = 'Sorry, amount is invalid.'
				,@ErrCode = 30001

			RETURN
		END

		IF (
				NOT EXISTS (
					SELECT 1
					FROM AffInfo(NOLOCK)
					WHERE AffID = @AffID
					)
				)
		BEGIN
			SELECT @ErrMsg = 'Invalid Affiliate!'
				,@ErrCode = 1001

			RETURN
		END

		DECLARE @Currency INT
			,@AffRate FLOAT
			,@Status VARCHAR(30)
			,@IsClosed BIT
			,@IsLocked BIT

		SELECT @Currency = b.Currency
			,@AffRate = e.ActualRate
			,@Status = STATUS
			,@IsClosed = IsClosed
			,@IsLocked = IsLocked
		FROM AffInfo b WITH (NOLOCK)
			INNER JOIN Exchange_Current e WITH (NOLOCK)
			ON b.Currency = e.ExchangeID
		WHERE b.AffID = @AffID

		--Check Data
		IF @Currency IS NULL --cannot find Affiliate 
		BEGIN
			SELECT @ErrMsg = 'Invalid Affiliate'
				,@ErrCode = 30002

			RETURN
		END

		IF @Status <> 'Approved'
		BEGIN
			SELECT @ErrMsg = 'Sorry, You cannot do adjustment because this Affiliate is not approved yet.'
				,@ErrCode = 30003

			RETURN
		END

		--IF (@IsClosed = 1 OR @IsLocked = 1)
		--BEGIN
		--	SELECT @ErrMsg = 'Sorry, You cannot do adjustment because this Affiliate is closed or locked.'
		--		,@ErrCode = 30004
		--	RETURN
		--END
		INSERT INTO AffTrans (
			[AffID]
			,[TransDate]
			,[CompletedDate]
			,[Amount]
			,[Status]
			,[Description]
			,[Creator]
			,[Currency]
			--This section no need to update ActualRate(Only apply for Payment Request)
			,[TransType]
			--,[RefID]
			,[AffExRate]
			)
		VALUES (
			@AffID
			,Getdate()
			,Getdate()
			,@Amount
			,'Completed'
			,@transdesc
			,@AdminID
			,@Currency
			,--Default for USD currency
			203
			,--Adjustment TransType
			--@RefNo,
			@AffRate
			)

		IF @@ERROR <> 0
		BEGIN
			SELECT @ErrMsg = 'This transaction is unsuccessful.'
				,@ErrCode = 4005

			RETURN
		END

		--Write log
		DECLARE @SPName VARCHAR(50)
			,@Detail NVARCHAR(4000)

		SELECT @SPName = OBJECT_NAME(@@ProcID)

		SELECT @Detail = 'Adjustment Insert. Amount = ' + dbo.Aff_ToString(@Amount)

		EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID
			,@AffID = @AffID
			,@Typename = 'Adjustment'
			,-- refer to table LogType
			@SPName = @SPName
			,@Details = @Detail
			,@IP = @IP
	END
END
GO

GRANT EXECUTE ON [dbo].[Aff_AdjustmentIns] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AdjustmentIns] TO [VNTeam]
