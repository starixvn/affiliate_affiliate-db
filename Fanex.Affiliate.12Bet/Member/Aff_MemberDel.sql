USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Aff_MemberDel]    Script Date: 11/9/2020 2:07:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Aff_MemberDel    Script Date: 4/24/2014 4:57:12 PM ******/
CREATE PROCEDURE [dbo].[Aff_MemberDel] 
	@IBCCustID INT
	,@UserID INT
	,@IP VARCHAR(20)
	,@AffID INT = NULL OUTPUT
	,@RefNo BIGINT = 0 OUTPUT
	,@DepositCustID INT = 0 OUTPUT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS

	/*
Created: 20090910@Peter
Task : Remove a member  from Affiliate
DB: DB052.Affiliate_12BET
Original: 

Revisions:
	Peter@20100413 : Remove the calling to sp [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
					coz AffiliateID in custinfo will be removed.  
	Johnny@20100512: Re-calculate AffDaily if member is removed.
	Peter@20100927 : Add OddsFee column for AffDetail
	-20140424@Bobby: formating code

Param's Explanation:
.@IP: ip of computer sent,
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.
• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------
	EXEC [dbo].[Aff_Con_CheckPermission] @custid = @UserID
		,@funcname = '[Affiliate]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 RETURN

	-----------------------------------------------
	--Check IBCCustID
	SELECT @AffId = AffId
		,@DepositCustID = DepositCustID
	FROM MemberInfo(NOLOCK)
	WHERE IBCCustID = @IBCCustID
		AND IsRemoved = 0

	IF (@AffID IS NULL)
	BEGIN
		SELECT @ErrMsg = 'This member does not exist or be removed before!'
			,@ErrCode = 1001

		RETURN
	END

	/*exec [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
	@IBCCustID =@IBCCustID,	
	@NewAffId =0,	
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg =@ErrMsg OUTPUT
	
if(@ErrCode<>0)
   return*/
	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100)
		,@FirstDayOfTheMonth SMALLDATETIME

	SELECT @LogData = 'Remove member. IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
		,@FirstDayOfTheMonth = dateadd(m, datediff(m, 0, Current_Timestamp), 0)

	BEGIN TRANSACTION

	BEGIN TRY
		--Write the log 
		/*select @SPName='Aff_MemberUpdAffID'
	EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@AffID,
		@Typename= 'Member',	
		@SPName=@SPName ,
		@RefNo=@RefNo OUTPUT,
		@IP =@IP,
		@Details=@LogData	*/
		UPDATE MemberInfo WITH (ROWLOCK, UPDLOCK)
		SET IsRemoved = 1
		WHERE IBCCustID = @IBCCustID

		INSERT INTO MemberDailyRemoved (
			[WinlostDate]
			,[IBCCustID]
			,[SportType]
			,[Currency]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[AWinlost]
			,[ABonus]
			,[AffExRate]
			,[MemberExRate]
			,[DrawGame]
			,[PSP]
			,[Marketing]
			,[AffID]
			,[MemWinlostFake]
			,[MemOddsFee]
			)
		SELECT [WinlostDate]
			,[IBCCustID]
			,[SportType]
			,[Currency]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[AWinlost]
			,[ABonus]
			,[AffExRate]
			,[MemberExRate]
			,[DrawGame]
			,[PSP]
			,[Marketing]
			,[AffID]
			,[MemWinlostFake]
			,[MemOddsFee]
		FROM MemberDaily WITH (NOLOCK)
		WHERE IBCCustID = @IBCCustID
			AND datediff(m, winlostdate, current_timestamp) = 0
			AND SportType > 0

		DELETE MemberDaily
		WHERE IBCCustID = @IBCCustID
			AND datediff(m, winlostdate, current_timestamp) = 0
			AND SportType > 0

		--Update AFFDaily here
		DELETE
		FROM AffDaily
		WHERE AffId = @AffId
			AND datediff(m, winlostdate, current_timestamp) = 0

		INSERT INTO AffDaily (
			[AffID]
			,[Currency]
			,[Winlostdate]
			,[SportID]
			,[ExRate2]
			,[MemDeposit]
			,[MemWithdrawal]
			,[MemTurnover]
			,[MemBonus]
			,[MemAdjustment]
			,[MemMarketing]
			,[MemPSP]
			,[MemWinlost]
			,[AffWinlost]
			,[HouseWinlost]
			,[AffNetWinlost]
			,[HouseNetWinlost]
			,[MemWinlostFake]
			,[MemOddsFee]
			)
		SELECT d.AffID AS AffID
			,d.Currency AS Currency
			,d.Winlostdate AS Winlostdate
			,d.SportType AS SportID
			,d.AffExRate AS Exrate2
			,SUM(isnull(d.Deposit, 0)) AS MemDeposit
			,SUM(isnull(d.Withdrawal, 0)) AS MemWithdrawal
			,SUM(isnull(d.Turnover, 0)) AS MemTurnover
			,SUM(isnull(d.Bonus, 0)) AS MemBonus
			,SUM(isnull(d.Adjustment, 0)) AS MemAdjustment
			,0 AS MemMarketing
			,SUM(isnull(d.PSP, 0)) AS MemPSP
			,SUM(isnull(d.Winlost, 0)) AS MemWinLost
			,0 AS AffWinLost
			,- SUM(d.Winlost) AS HouseWinLost
			,0 AS AffNetWinlost
			,0 AS HouseNetWinLost
			,0 AS MemWinlostFake
			,0 AS MemOddsFee
		FROM MemberDaily d WITH (NOLOCK)
		WHERE AffId = @AffId
			AND d.WinlostDate >= @FirstDayOfTheMonth
		GROUP BY d.AffID
			,d.Winlostdate
			,d.Currency
			,d.SportType
			,d.AffExRate

		UPDATE AffDaily WITH (ROWLOCK, UPDLOCK)
		SET [MemMarketing] = abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0)
			,MemOddsFee = abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0)
			,HouseNetWinLost = HouseWinLost - isnull(MemBonus, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', Winlostdate), 0) - isnull(MemAdjustment, 0) - isnull(MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0)
			,MemWinlostFake = - (- isnull(MemWinlost, 0) - isnull(MemPSP, 0) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', Winlostdate), 0) - abs(isnull(MemWinlost, 0)) * isnull(dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', Winlostdate), 0))
		WHERE AffId = @AffId
			AND WinlostDate >= @FirstDayOfTheMonth

		DELETE
		FROM AffDailySummary
		WHERE AffId = @AffId
			AND WinlostDate >= @FirstDayOfTheMonth

		INSERT INTO [dbo].[AffDailySummary] (
			[AffID]
			,[Winlostdate]
			,[SportID]
			,[MemDeposit]
			,[MemWithdrawal]
			,[MemTurnover]
			,[MemBonus]
			,[MemAdjustment]
			,[MemMarketing]
			,[MemPSP]
			,[MemWinlost]
			,[AffWinlost]
			,[HouseWinlost]
			,[AffNetWinlost]
			,[HouseNetWinlost]
			,[MemOddsFee]
			,[MemWinlostFake]
			)
		SELECT [AffID]
			,[Winlostdate]
			,[SportID]
			,sum([MemDeposit] * ExRate2) AS MemDeposit
			,sum([MemWithdrawal] * ExRate2) AS MemWithdrawal
			,sum([MemTurnover] * ExRate2) AS MemTurnover
			,sum([MemBonus] * ExRate2) AS MemBonus
			,sum([MemAdjustment] * ExRate2) AS MemAdjustment
			,0 AS MemMarketing
			,sum([MemPSP] * ExRate2) AS MemPSP
			,sum([MemWinlost] * ExRate2) AS MemWinlost
			,sum([AffWinlost] * ExRate2) AS AffWinlost
			,sum([HouseWinlost] * ExRate2) AS HouseWinlost
			,sum([AffNetWinlost] * ExRate2) AS AffNetWinlost
			,sum([HouseNetWinlost] * ExRate2) AS HouseNetWinlost
			,0 AS MemOddsFee
			,0 AS MemWinlostFake
		FROM AffDaily(NOLOCK)
		WHERE AffId = @AffId
			AND WinlostDate >= @FirstDayOfTheMonth
		GROUP BY AffID
			,Winlostdate
			,SportID

		UPDATE AffDailySummary WITH (ROWLOCK, UPDLOCK)
		SET MemOddsFee = abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate)
			,MemMarketing = abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate)
			,MemWinlostFake = - (- MemWinlost - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate) - MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate))
			,HouseNetWinlost = (- MemWinlost - MemBonus * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Bonus', WinlostDate) - MemAdjustment - MemPSP * dbo.Aff_GetDeductionPercent(AffID, SportID, 'PSP', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Marketing', WinlostDate) - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID, SportID, 'Odds Fee', WinlostDate))
		WHERE AffId = @AffId
			AND WinlostDate >= @FirstDayOfTheMonth

		INSERT INTO MemberRemoval (
			IBCCustID
			,RemovedDate
			,RemovedBy
			)
		VALUES (
			@IBCCustID
			,current_timestamp
			,@UserID
			)
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION

		--manually rollback on DB02 
		/*exec [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
			@IBCCustID =@IBCCustID,			
			@NewAffId =@AffID,				
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg =@ErrMsg OUTPUT*/
		SELECT @ErrMsg = 'Remove member failed!'
			,@ErrCode = 1002

		RETURN
	END CATCH

	COMMIT TRANSACTION

	--Write the log 
	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@AffID = @AffID
		,@Typename = 'Member'
		,@SPName = @SPName
		,@RefNo = @RefNo
		,@IP = @IP
		,@Details = @LogData
END
GO

GRANT EXECUTE ON [dbo].[Aff_MemberDel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDel] TO [vnAffiliate] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDel] TO [vnteam] AS [dbo]
GO


