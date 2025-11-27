/*<info serverAlias="DB12B-bodb_12B" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_API_ExchangeDailyOanda_Bid_Ins]
(
	@Code VARCHAR(12)
	, @MYR FLOAT
	, @USD FLOAT
	, @EUR FLOAT
	, @CNY FLOAT
	, @IDR FLOAT
	, @AUD FLOAT
	, @CHF FLOAT
	, @GBP FLOAT
	, @SGD FLOAT
	, @THB FLOAT
	, @VND FLOAT
	, @KRW FLOAT
	, @JPY FLOAT
	, @HKD FLOAT
	, @TWD FLOAT
	, @PHP FLOAT
	, @BDT FLOAT
	, @INR FLOAT
	, @TRY FLOAT
	, @NPR FLOAT
	, @MXN FLOAT
	, @NGN FLOAT
	, @BRL FLOAT
	, @PKR FLOAT
	, @ZAR FLOAT
	, @rundate DATETIME = NULL
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: 20251112@Sophia
	Task: Insert the Bid rate daily into ExchangeDailyOanda_Bid
	DB: DB12B-bodb_12B
	
	Revisions:
		- 20251112@Sophia: Initialize SP for ExchangeDailyOanda_Bid [RedmineID: #243773]
		
	Parameter's Explanation:
	-- Sample execution
	/*
	DECLARE @p28 INT, @p29 NVARCHAR(200)
	SET @p28 = 0
	SET @p29 = N''
	
	EXEC Aff_API_ExchangeDailyOanda_Bid_Ins 
		@Code = 'USD',
		@MYR = 4.45,
		@USD = 1,
		@EUR = 0.92,
		@CNY = 7.24,
		@IDR = 15680,
		@AUD = 1.53,
		@CHF = 0.88,
		@GBP = 0.79,
		@SGD = 1.34,
		@THB = 35.12,
		@VND = 24500,
		@KRW = 1320,
		@JPY = 149.5,
		@HKD = 7.82,
		@TWD = 31.5,
		@PHP = 55.8,
		@BDT = 110,
		@INR = 83.2,
		@TRY = 28.5,
		@NPR = 132,
		@MXN = 17.2,
		@NGN = 760,
		@BRL = 5.0,
		@PKR = 278,
		@ZAR = 18.5,
		@rundate = '2025-11-12 00:00:00',
		@ErrCode = @p28 OUTPUT,
		@ErrMsg = @p29 OUTPUT
	
	SELECT @p28 AS ErrCode, @p29 AS ErrMsg
	*/
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @exchange TABLE (id INT IDENTITY(1, 1), exchangeid INT, MultipliedBy FLOAT)

	DECLARE @date DATETIME
		  , @i INT
		  , @max INT
		  , @ExchangeId INT
		  , @MultipliedBy FLOAT

	-- Set the date
	IF @rundate IS NULL
		SET @date = CONVERT(DATETIME, CONVERT(NVARCHAR(20), GETDATE(), 101))
	ELSE
		SET @date = CONVERT(DATETIME, CONVERT(NVARCHAR(20), @rundate, 101))

	-- Get all exchange IDs for the given code
	INSERT INTO @exchange (exchangeid, MultipliedBy)
	SELECT exchangeid, MultipliedBy
	FROM bodb02.dbo.Exchange WITH (NOLOCK)
	WHERE Code = @Code

	IF @@ROWCOUNT > 0
	BEGIN
		SET @i = 1

		SELECT @max = COUNT(1)
		FROM @exchange

		WHILE (@i <= @max)
		BEGIN
			SELECT @ExchangeId = exchangeid
				 , @MultipliedBy = MultipliedBy
			FROM @exchange
			WHERE id = @i

			-- Check if record exists, if not then insert, otherwise update
			IF NOT EXISTS ( SELECT 1
							FROM ExchangeDailyOanda_Bid WITH (NOLOCK)
							WHERE ExchangeId = @ExchangeId
							  AND ExchangeDate = @date
							  AND Code = @Code )
			BEGIN
				-- Insert new record
				INSERT INTO ExchangeDailyOanda_Bid (
					ExchangeId
					, ExchangeDate
					, Code
					, MYR
					, USD
					, EUR
					, CNY
					, IDR
					, AUD
					, CHF
					, GBP
					, SGD
					, THB
					, VND
					, KRW
					, JPY
					, HKD
					, TWD
					, PHP
					, BDT
					, INR
					, TRY
					, NPR
					, MXN
					, NGN
					, BRL
					, PKR
					, ZAR
				)
				VALUES (
					@ExchangeId
					, @date
					, @Code
					, @MYR * @MultipliedBy
					, @USD * @MultipliedBy
					, @EUR * @MultipliedBy
					, @CNY * @MultipliedBy
					, @IDR * @MultipliedBy
					, @AUD * @MultipliedBy
					, @CHF * @MultipliedBy
					, @GBP * @MultipliedBy
					, @SGD * @MultipliedBy
					, @THB * @MultipliedBy
					, @VND * @MultipliedBy
					, @KRW * @MultipliedBy
					, @JPY * @MultipliedBy
					, @HKD * @MultipliedBy
					, @TWD * @MultipliedBy
					, @PHP * @MultipliedBy
					, @BDT * @MultipliedBy
					, @INR * @MultipliedBy
					, @TRY * @MultipliedBy
					, @NPR * @MultipliedBy
					, @MXN * @MultipliedBy
					, @NGN * @MultipliedBy
					, @BRL * @MultipliedBy
					, @PKR * @MultipliedBy
					, @ZAR * @MultipliedBy
				)
			END
			ELSE
			BEGIN
				-- Update existing record
				UPDATE ExchangeDailyOanda_Bid WITH (ROWLOCK, UPDLOCK)
				SET MYR = @MYR * @MultipliedBy
					, USD = @USD * @MultipliedBy
					, EUR = @EUR * @MultipliedBy
					, CNY = @CNY * @MultipliedBy
					, IDR = @IDR * @MultipliedBy
					, AUD = @AUD * @MultipliedBy
					, CHF = @CHF * @MultipliedBy
					, GBP = @GBP * @MultipliedBy
					, SGD = @SGD * @MultipliedBy
					, THB = @THB * @MultipliedBy
					, VND = @VND * @MultipliedBy
					, KRW = @KRW * @MultipliedBy
					, JPY = @JPY * @MultipliedBy
					, HKD = @HKD * @MultipliedBy
					, TWD = @TWD * @MultipliedBy
					, PHP = @PHP * @MultipliedBy
					, BDT = @BDT * @MultipliedBy
					, INR = @INR * @MultipliedBy
					, TRY = @TRY * @MultipliedBy
					, NPR = @NPR * @MultipliedBy
					, MXN = @MXN * @MultipliedBy
					, NGN = @NGN * @MultipliedBy
					, BRL = @BRL * @MultipliedBy
					, PKR = @PKR * @MultipliedBy
					, ZAR = @ZAR * @MultipliedBy
				WHERE ExchangeId = @ExchangeId
				  AND ExchangeDate = @date
				  AND Code = @Code
			END

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Exchange Bid rate insert/update fail.'
					 , @ErrCode = 100

				RETURN
			END

			SET @i = @i + 1
		END
	END
	ELSE
	BEGIN
		-- No exchange found for the given code
		SELECT @ErrMsg = 'No exchange found for code: ' + @Code
			 , @ErrCode = 101

		RETURN
	END

	-- Success
	SELECT @ErrMsg = ''
		 , @ErrCode = 0
END
GO
