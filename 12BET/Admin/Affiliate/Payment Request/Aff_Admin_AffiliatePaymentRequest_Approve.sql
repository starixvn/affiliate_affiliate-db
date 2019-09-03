/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Approve]
	@RefID				BIGINT
	,@AffUserName		NVARCHAR(50)
	,@Player_IBCCustID	INT
	,@Player_Currency	INT
	,@Ballance_CustID	INT
	,@AffPayout			MONEY
	,@UserID			INT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20160614@Percy
	DB: DBTXN.bodb02
	Task: Admin - Affiliate - Payment Request - Approve payment request

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
*/

BEGIN
	DECLARE @Player_UserName		NVARCHAR(50)
			,@Player_recommend		INT
			,@Player_mrecommend		INT
			,@Player_srecommend		INT
			,@Player_CurrencyName	VARCHAR(50)
			,@Player_ExRate			FLOAT

			,@Ballance_UserName		NVARCHAR(50)
			,@Ballance_recommend	INT
			,@Ballance_mrecommend	INT
			,@Ballance_srecommend	INT

	SELECT	@Player_UserName	= username
			,@Player_recommend	= recommend
			,@Player_mrecommend = mrecommend
			,@Player_srecommend = srecommend
	FROM CustDB.dbo.Customer WITH (NOLOCK)
	WHERE custid = @Player_IBCCustID

	SELECT	@Ballance_UserName		= username
			,@Ballance_recommend	= recommend
			,@Ballance_mrecommend	= mrecommend
			,@Ballance_srecommend	= srecommend
	FROM CustDB.dbo.Customer WITH (NOLOCK)
	WHERE custid = @Ballance_CustID

	SELECT	@Player_CurrencyName	= Currency
			,@Player_ExRate			= actualrate
	FROM CustDB.dbo.Exchange WITH (NOLOCK)
	WHERE ExchangeID = @Player_Currency

	IF @Player_recommend IS NULL OR @Ballance_recommend IS NULL OR @Player_CurrencyName IS NULL
	BEGIN
		-- Invalid Account.
		SELECT @ErrCode = 4001, @ErrMsg = ' Invalid Account.'
		RETURN
	END

	DECLARE @TransDesc		NVARCHAR(1000)
			,@TransDate		SMALLDATETIME
			,@WinlostDate	SMALLDATETIME
			,@BetType		INT
			,@Status		NVARCHAR(10)
			,@StatusID		TINYINT
	SELECT  @TransDesc		= 'Approve payout Request from affiliate ' + @AffUserName + ' to his player account: ' + @Player_UserName
			,@TransDate		= GETDATE()
			,@WinlostDate	= CONVERT(DATE, @TransDate)
			,@BetType		= 21006
			,@Status		= 'Approved'
			,@StatusID		= 132
	
	DECLARE @TransID1 BIGINT, @TransID2 BIGINT, @Amount MONEY
	SELECT  @Amount = ABS(@AffPayout)

	BEGIN TRY
		-- Add money to player
		INSERT INTO dbo.bettrans
		(
			custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, winlostdate
			,creator, recommend, mrecommend, srecommend, currency, actualrate, currencyName, ruben, status, ip, StatusID
		)
		VALUES
		(
			@Player_IBCCustID, @Player_UserName, @RefID, @TransDate, 0, @BetType, @TransDesc, @Amount, 0, @WinlostDate
			,@UserID, @Player_Recommend, @Player_MRecommend, @Player_SRecommend, @Player_Currency, @Player_ExRate, @Player_CurrencyName, 1, @Status, @ip, @StatusID
		)
	
		SELECT @TransID1 = SCOPE_IDENTITY()

		EXEC Dot_BalanceCreditUpd @CustID = @Player_IBCCustID, @balance = @Amount, @type = 2

		-- Deduct balance account
		INSERT INTO dbo.bettrans
		(
			custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, winlostdate
			,creator, recommend, mrecommend, srecommend, currency, actualrate, currencyName, ruben, status, ip, StatusID
		)
		VALUES
		(
			@Ballance_CustID, @Ballance_UserName, @RefID, @TransDate, 0, @BetType, @TransDesc, 0, @Amount, @WinlostDate
			,@UserID, @Ballance_Recommend, @Ballance_MRecommend, @Ballance_SRecommend, @Player_Currency, @Player_ExRate, @Player_CurrencyName, 1, @Status, @ip, @StatusID
		)
    
		SELECT @TransID2 = SCOPE_IDENTITY()

		EXEC Dot_BalanceDebitUpd @CustID = @Ballance_CustID, @balance = @Amount, @type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT

		IF @ErrCode <> 0
		BEGIN
			-- Rollback bettrans
			DELETE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
			WHERE transid IN (@TransID1, @TransID2)

			SELECT @ErrCode = 4002, @ErrMsg = 'Update transaction failed.'
			RETURN
		END
	END TRY
	BEGIN CATCH
		-- Rollback bettrans
		DELETE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
		WHERE transid IN (@TransID1, @TransID2)

		SELECT @ErrCode = 4003, @ErrMsg = 'Insert transaction failed.'
		RETURN
	END CATCH
END
GO