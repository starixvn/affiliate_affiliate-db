/*<info serverAlias="DBCTG-bodb02, DBSID-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Approve]
 @RefID    			BIGINT  
 ,@AffUserName  	NVARCHAR(50)  
 ,@Player_IBCCustID INT  
 ,@Player_Currency 	INT  
 ,@Ballance_CustID 	INT  
 ,@AffPayout   		MONEY  
 ,@UserID   		INT  
 ,@IP    			VARCHAR(50) = ''  
 ,@ErrCode   		INT = 0 OUTPUT  
 ,@ErrMsg   		NVARCHAR(4000) = '' OUTPUT  
AS

/*
	Created: 20160614@Percy
	DB: DBCTG.bodb02, DBSID.bodb02
	Task: Admin - Affiliate - Payment Request - Approve payment request

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20211222@Malcolm: Split transfer out of bettrans [RedmineID: #165095]
		- 20211222@Malcolm: get transid from Get_Bettrans_TransID [RedmineID: #175407]
		- 20230621@Eddie: Migrate 12Bet to SiteDB02 [RedmineID: #189465]
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
	
	-- For Log  
	DECLARE @LogData VARCHAR(1000), @SPName VARCHAR(50)
	SELECT @SPName = OBJECT_NAME(@@PROCID)
	SELECT @LogData = 'Insert Transfer with RefID = ' + ISNULL(CONVERT(VARCHAR(20), @RefID), '') + ', AffUserName = ' + ISNULL(CONVERT(VARCHAR(20), @AffUserName), '') + ', Player_Currency = ' + ISNULL(CONVERT(VARCHAR(20), @Player_Currency), '') + ', AffPayout = ' + ISNULL(CONVERT(VARCHAR(20), @AffPayout), '') + ', SPName = ' + @SPName
	
	IF @Player_recommend IS NULL OR @Ballance_recommend IS NULL OR @Player_CurrencyName IS NULL
	BEGIN
		-- Invalid Account.
		SELECT @ErrCode = 4001, @ErrMsg = 'Invalid Account.'
		RETURN
	END

	DECLARE @TransDesc		NVARCHAR(1000)
			,@TransDate		SMALLDATETIME
			,@WinlostDate	SMALLDATETIME
			,@BetType		INT
			,@StatusID		TINYINT
	SELECT  @TransDesc		= 'Approve payout Request from affiliate ' + @AffUserName + ' to his player account: ' + @Player_UserName
			,@TransDate		= GETDATE()
			,@WinlostDate	= CONVERT(DATE, @TransDate)
			,@BetType		= 21006
			,@StatusID		= 132
	
	DECLARE @TransID1 BIGINT, @TransID2 BIGINT = NULL, @Amount MONEY
	SELECT  @Amount = ABS(@AffPayout)

	EXEC Get_Bettrans_TransID @TransID = @TransID1 OUTPUT

	-- Add money to player
	BEGIN TRY
		INSERT INTO dbo.Transfer
		(
			TransId, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, winlostdate
			,creator, recommend, mrecommend, srecommend, currency, actualrate, currencyName, ip, StatusID, RepUpdateTime
		)
		VALUES
		(
			@TransID1, @Player_IBCCustID, @Player_UserName, @RefID, @TransDate, @BetType, @TransDesc, @Amount, 0, @WinlostDate
			,@UserID, @Player_Recommend, @Player_MRecommend, @Player_SRecommend, @Player_Currency, @Player_ExRate, @Player_CurrencyName, @ip, @StatusID, SYSDATETIME()
		)
	
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 4003, @ErrMsg = 'Insert transaction failed.'
		RETURN
	END CATCH

	EXEC Dot_BalanceCreditUpd @CustID = @Player_IBCCustID, @balance = @Amount, @type = 2, @ErrCode = @ErrCode OUTPUT
	
	IF @ErrCode <> 0
	BEGIN
	
		WAITFOR DELAY '000:00:00.002' -- wait for in-house service  
  
		--Manually Rollback
		UPDATE dbo.Transfer WITH (ROWLOCK, UPDLOCK)
		SET CustId 			= 0
			,Recommend 		= 0
			,MRecommend 	= 0
			,SRecommend 	= 0
			,Winlost 		= 0
			,Actual_Stake 	= 0
			,RepUpdateTime 	= SYSDATETIME()  
		WHERE TransId = @TransID1

		SELECT @ErrCode = 4002, @ErrMsg = 'Update transaction failed.'
		RETURN
	END

	EXEC Get_Bettrans_TransID @TransID = @TransID2 OUTPUT

	-- Deduct balance account
	BEGIN TRY
		INSERT INTO dbo.Transfer
		(
			TransId, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, winlostdate
			,creator, recommend, mrecommend, srecommend, currency, actualrate, currencyName, ip, StatusID, RepUpdateTime
		)
		VALUES
		(
			@TransID2, @Ballance_CustID, @Ballance_UserName, @RefID, @TransDate, @BetType, @TransDesc, 0, @Amount, @WinlostDate
			,@UserID, @Ballance_Recommend, @Ballance_MRecommend, @Ballance_SRecommend, @Player_Currency, @Player_ExRate, @Player_CurrencyName, @ip, @StatusID, SYSDATETIME()
		)
   
	END TRY
	BEGIN CATCH 
	
		WAITFOR DELAY '000:00:00.002' -- wait for in-house service  
  
		--Manually rollback  
		UPDATE dbo.Transfer WITH (ROWLOCK, UPDLOCK)
		SET CustId 			= 0
			,Recommend 		= 0
			,MRecommend 	= 0
			,SRecommend 	= 0
			,Winlost 		= 0
			,Actual_Stake 	= 0
			,RepUpdateTime 	= SYSDATETIME()  
		WHERE TransId IN (@TransID1, @TransID2)

		EXEC Dot_BalanceDebitUpd @CustID = @Player_IBCCustID, @balance = @Amount, @type = 2, @IsForced = 1

		SELECT @ErrCode = 4002, @ErrMsg = 'Update transaction failed.'
		RETURN
	END CATCH

	EXEC Dot_BalanceDebitUpd @CustID = @Ballance_CustID, @balance = @Amount, @type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT

	IF @ErrCode <> 0
	BEGIN
	
		WAITFOR DELAY '000:00:00.002' -- wait for in-house service  
  
		--Manually rollback  
		UPDATE dbo.Transfer WITH (ROWLOCK, UPDLOCK)
		SET CustId 			= 0
			,Recommend 		= 0
			,MRecommend 	= 0
			,SRecommend 	= 0
			,Winlost 		= 0
			,Actual_Stake 	= 0
			,RepUpdateTime 	= SYSDATETIME()  
		WHERE TransId IN (@TransID1, @TransID2)

		EXEC Dot_BalanceDebitUpd @CustID = @Player_IBCCustID, @balance = @Amount, @type = 2, @IsForced = 1

		SELECT @ErrCode = 4002, @ErrMsg = 'Update transaction failed.'
		RETURN
	END
	
	-- Write Log
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer   
			@UserID  		= @UserId 
			,@FromCustID 	= @Player_IBCCustID
			,@ToCustID 		= @Ballance_CustID
			,@IP   			= @IP
			,@Doing  		= @LogData

	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
		SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
		
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer   
			@UserID  		= @UserId
			,@FromCustID 	= @Player_IBCCustID
			,@ToCustID 		= @Ballance_CustID
			,@IP   			= @IP
			,@Doing  		= @LogData 

	END CATCH 
END
GO