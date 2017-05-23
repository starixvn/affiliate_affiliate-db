USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_HomeGeneralInfo] 
	@LicenseeID INT,
	@UserId INT = 0
AS

/*
	Created: 20090828@Bryan    
	Task: Gather overview statistic information of aff-admin site    
	DB: DBAFF.Affiliate_Athena000    
    
	Revisions:    
		- 20090829@Bryan initialize    
		- 20100520@Johnny: apply StatusID in bettrans table    
		- 20100729@Johnny: Apply Media affiliate statistics    
		- 20131007@Johnny: Get Turnover
		- 20140515@bobby: Exclude member test account
		- 20140703@bobby: Exclude Payment info that belongs to affiliate test account
		- 20140819@Bobby: Apply SQL style scope
		- 20150107@Bobby: Update counting bannset stats info
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site

	Param's Explanation:    

*/

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @MemInProAllNum 	INT
		,@MemInProMonthNum 		INT
		,@NonDepositMemMonthNum INT
		
	--Variables for Normal Affiliate    
	DECLARE @PaymentReqNum 		INT
		,@AffInProAllNum 		INT
		,@PendingAllNum 		INT
		,@ApprovedAllNum 		INT
		,@DisapprovedAllNum 	INT
		,@ClosedAllNum 			INT
		,@DepositMemAllNum 		INT
		,@DepositAll 			MONEY
		,@WinlostAll 			MONEY
		,@BonusAll 				MONEY
		,@PSPFeeAll 			MONEY
		,@AdjustmentAll 		MONEY
		,@TurnoverAll 			MONEY
		,@WithdrawalAll 		MONEY
		,@NetWinlostAll 		MONEY
		,@BannerNum 			INT
		,@ImageBannerNum 		INT
		,@FlashBannerNum 		INT
		,@MediaImageBannerNum 	INT
		,@MediaFlashBannerNum 	INT
		,@KioskImageBannerNum 	INT
		,@KioskFlashBannerNum 	INT
		,@AffInProMonthNum 		INT
		,@PendingMonthNum 		INT
		,@ApprovedMonthNum 		INT
		,@DisapprovedMonthNum 	INT
		,@ClosedMonthNum 		INT
		,@DepositMemMonthNum 	INT
		,@DepositMonth 			MONEY
		,@WinlostMonth 			MONEY
		,@BonusMonth 			MONEY
		,@PSPFeeMonth 			MONEY
		,@AdjustmentMonth 		MONEY
		,@TurnoverMonth 		MONEY
		,@WithdrawalMonth 		MONEY
		,@NetWinlostMonth 		MONEY
		,@LockedAllNum 			INT
		,@LockedMonthNum 		INT
		,@TransType 			INT
		,@CurrentDate 			SMALLDATETIME
		,@AffNormal 			TINYINT
		,@AffMedia 				TINYINT;
		
	--dflag=0 : for all previous months data    
	-- dflag=1 : for current month data    
	DECLARE @tmpCurrency TABLE (
		CurrencyID INT
		,ExRate FLOAT
		)

	SELECT @CurrentDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
		,@AffNormal = 1
		,@AffMedia = 2
		,@TransType = 202 -- payment request    

	INSERT INTO @tmpCurrency
	SELECT AffCurrencyID
		,0 AS ExRate
	FROM dbo.AffAdmin_f_UserCurrency_Select(@userID, @LicenseeID)

	SELECT @PaymentReqNum = SUM(1)
	FROM dbo.AffTrans af WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON af.AffId = ai.AffId 
	WHERE af.TransType = @TransType 
		AND af.AffCurrency IN (
			SELECT CurrencyID
			FROM @tmpCurrency
		) 
		AND af.STATUS = 'Pending'
		AND ai.TestLevel = 0
		AND ai.STATUS = 'Approved'

	-- all affiliate statc      
	SELECT @PendingAllNum = SUM(CASE 
				WHEN STATUS = 'Pending' THEN 1
				ELSE 0
				END)
		,@ApprovedAllNum = SUM(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 0 AND IsLocked = 0 THEN 1
				ELSE 0
				END)
		,@DisapprovedAllNum = SUM(CASE 
				WHEN STATUS = 'Disapproved' THEN 1
				ELSE 0
				END)
		,@ClosedAllNum = SUM(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 1 THEN 1
				ELSE 0
				END)
		,@LockedAllNum = SUM(CASE 
				WHEN STATUS = 'Approved' AND IsLocked = 1 THEN 1
				ELSE 0
				END)
		,@AffInProAllNum = SUM(1)
		,@AffInProMonthNum = SUM(CASE 
				WHEN datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@PendingMonthNum = SUM(CASE 
				WHEN STATUS = 'pending' AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@ApprovedMonthNum = SUM(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 0 AND IsLocked = 0 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@DisapprovedMonthNum = SUM(CASE 
				WHEN STATUS = 'Disapproved' AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@ClosedMonthNum = SUM(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 1 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@LockedMonthNum = SUM(CASE 
				WHEN STATUS = 'Approved' AND IsLocked = 1 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN @tmpCurrency t ON AI.Currency = t.CurrencyID
	WHERE ai.TestLevel = 0

	-- //all banner statc    
	SELECT @BannerNum = SUM(CASE 
				WHEN bt.Value IN ('Image', 'Flash') THEN 1
				ELSE 0
				END)
		,@ImageBannerNum = SUM(CASE 
				WHEN bt.Value = 'Image' AND b.Type = 1 THEN 1
				ELSE 0
				END)
		,@FlashBannerNum = SUM(CASE 
				WHEN bt.Value = 'Flash' AND b.Type = 1 THEN 1
				ELSE 0
				END)
		,@MediaImageBannerNum = SUM(CASE 
				WHEN bt.Value = 'Image' AND b.Type = 2 THEN 1
				ELSE 0
				END)
		,@MediaFlashBannerNum = SUM(CASE 
				WHEN bt.Value = 'Flash' AND b.Type = 2 THEN 1
				ELSE 0
				END)
		,@KioskImageBannerNum = SUM(CASE 
				WHEN bt.Value = 'Image' AND b.Type = 3 THEN 1
				ELSE 0
				END)
		,@KioskFlashBannerNum = SUM(CASE 
				WHEN bt.Value = 'Flash' AND b.Type = 3 THEN 1
				ELSE 0
				END)
	FROM dbo.Banners b WITH (NOLOCK)
		LEFT JOIN BannerTypes bts ON (bts.TypeID = b.Size AND bts.Type = 'Size')
		LEFT JOIN BannerTypes bt ON (bt.TypeID = b.ImageType AND bt.Type = 'ImageType')
		INNER JOIN BannerTypes btc ON (btc.TypeID = b.Category	AND btc.Type IN ('MediaCategory','MediaSubCategory'))
		INNER JOIN LANGUAGE l ON l.LanguageID = b.LANGUAGE
		INNER JOIN Currency c ON c.CurrencyID = b.Currency

	DECLARE @MaxWinLostDateAffComm 	SMALLDATETIME
		,@NextMaxWinlostDate 		SMALLDATETIME

	SELECT @MaxWinLostDateAffComm = max(winlostdate)
	FROM dbo.AffCommission WITH (NOLOCK)

	SELECT @NextMaxWinlostDate = dateadd(d, 1, @MaxWinLostDateAffComm)

	--Get statistics of normal affiliate    
				EXEC [AffAdmin_GetMemberStatistics] 
		@LicenseeID			= @LicenseeID
		,@UserId 			= @UserId
		,@DepositAll 		= @DepositAll 		OUTPUT
		,@DepositMonth 		= @DepositMonth 	OUTPUT
		,@PSPFeeAll 		= @PSPFeeAll 		OUTPUT
		,@PSPFeeMonth 		= @PSPFeeMonth 		OUTPUT
		,@WinlostAll 		= @WinlostAll 		OUTPUT
		,@WinlostMonth 		= @WinlostMonth 	OUTPUT
		,@BonusAll 			= @BonusAll 		OUTPUT
		,@BonusMonth 		= @BonusMonth 		OUTPUT
		,@AdjustmentAll 	= @AdjustmentAll	OUTPUT
		,@AdjustmentMonth 	= @AdjustmentMonth 	OUTPUT
		,@TurnoverAll 		= @TurnoverAll 		OUTPUT
		,@TurnoverMonth 	= @TurnoverMonth 	OUTPUT
		,@NetWinlostAll 	= @NetWinlostAll 	OUTPUT
		,@NetWinlostMonth 	= @NetWinlostMonth 	OUTPUT
		,@WithdrawalAll 	= @WithdrawalAll 	OUTPUT
		,@WithdrawalMonth 	= @WithdrawalMonth 	OUTPUT

	SELECT @DepositMemAllNum = SUM(CASE 
				WHEN CreatedDate IS NOT NULL THEN 1
				ELSE 0
				END)
		,@DepositMemMonthNum = SUM(CASE 
				WHEN datediff(m, m.CreatedDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@MemInProAllNum = count(1)
		,@MemInProMonthNum = SUM(CASE 
				WHEN datediff(m, m.RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@NonDepositMemMonthNum = SUM(CASE 
				WHEN datediff(m, m.RegisteredDate, @CurrentDate) = 0 AND CreatedDate IS NULL THEN 1
				ELSE 0
				END)
	FROM dbo.MemberInfo m WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON m.AffId = ai.AffId
	WHERE m.IsRemoved = 0
		AND ai.TestLevel = 0

	--final result here    
	SELECT ISNULL(@PaymentReqNum, 0) AS PaymentReqNum
		,ISNULL(@AffInProAllNum, 0) AS AffInProAllNum
		,ISNULL(@PendingAllNum, 0) AS PendingAllNum
		,ISNULL(@ApprovedAllNum, 0) AS ApprovedAllNum
		,ISNULL(@DisapprovedAllNum, 0) AS DisapprovedAllNum
		,ISNULL(@DepositMemAllNum, 0) AS DepositMemAllNum
		,ISNULL(@ClosedAllNum, 0) AS ClosedAllNum
		,ISNULL(@DepositAll, 0) AS DepositAll
		,ISNULL(@WinlostAll, 0) AS WinlostAll
		,ISNULL(@BonusAll, 0) AS BonusAll
		,ISNULL(@PSPFeeAll, 0) AS PSPFeeAll
		,ISNULL(@AdjustmentAll, 0) AS AdjustmentAll
		,ISNULL(@TurnoverAll, 0) AS TurnoverAll
		,ISNULL(@WithdrawalAll, 0) AS WithdrawalAll
		,ISNULL(@NetWinlostAll, 0) AS NetWinlostAll
		,ISNULL(@BannerNum, 0) AS BannerNum
		,ISNULL(@ImageBannerNum, 0) AS ImageBannerNum
		,ISNULL(@FlashBannerNum, 0) AS FlashBannerNum
		,ISNULL(@MediaImageBannerNum, 0) AS MediaImageBannerNum
		,ISNULL(@MediaFlashBannerNum, 0) AS MediaFlashBannerNum
		,ISNULL(@KioskImageBannerNum, 0) AS KioskImageBannerNum
		,ISNULL(@KioskFlashBannerNum, 0) AS KioskFlashBannerNum
		,ISNULL(@AffInProMonthNum, 0) AS AffInProMonthNum
		,ISNULL(@PendingMonthNum, 0) AS PendingMonthNum
		,ISNULL(@ApprovedMonthNum, 0) AS ApprovedMonthNum
		,ISNULL(@DisapprovedMonthNum, 0) AS DisapprovedMonthNum
		,ISNULL(@ClosedMonthNum, 0) AS ClosedMonthNum
		,ISNULL(@DepositMemMonthNum, 0) AS DepositMemMonthNum
		,ISNULL(@DepositMonth, 0) AS DepositMonth
		,ISNULL(@WinlostMonth, 0) AS WinlostMonth
		,ISNULL(@BonusMonth, 0) AS BonusMonth
		,ISNULL(@PSPFeeMonth, 0) AS PSPFeeMonth
		,ISNULL(@AdjustmentMonth, 0) AS AdjustmentMonth
		,ISNULL(@TurnoverMonth, 0) AS TurnoverMonth
		,ISNULL(@WithdrawalMonth, 0) AS WithdrawalMonth
		,ISNULL(@NetWinlostMonth, 0) AS NetWinlostMonth
		,ISNULL(@LockedAllNum, 0) AS LockedAllNum
		,ISNULL(@LockedMonthNum, 0) AS LockedMonthNum
		,ISNULL(@MemInProAllNum, 0) AS MemInProAllNum
		,ISNULL(@MemInProMonthNum, 0) AS MemInProMonthNum
		,ISNULL(@NonDepositMemMonthNum, 0) AS NonDepositMemMonthNum
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_HomeGeneralInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_HomeGeneralInfo] TO [vnteam] AS [dbo]