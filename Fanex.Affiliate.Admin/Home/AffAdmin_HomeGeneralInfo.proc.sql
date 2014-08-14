ALTER PROCEDURE [dbo].[AffAdmin_HomeGeneralInfo] 
	@UserId INT = 0
AS
/*Created: 20090828@Bryan    
Task : Gather overview statistic information of aff-admin site    
DB: DB052.Affiliate_MYM    
    
Revisions:    
 - 20090829@Bryan initialize    
 - 20100520@Johnny: apply StatusID in bettrans table    
 - 20100729@Johnny: Apply Media affiliate statistics    
 - 20131007@Johnny: Get Turnover
 - 20140515@bobby: Exclude member test account
 - 20140703@bobby: Exclude Payment info that belongs to affiliate test account

Param's Explanation:    
    
*/
BEGIN
	DECLARE @MemInProAllNum INT
		,@MemInProMonthNum INT
		,@NonDepositMemMonthNum INT
	--Variables for Normal Affiliate    
	DECLARE @PaymentReqNum INT
		,@AffInProAllNum INT
		,@PendingAllNum INT
		,@ApprovedAllNum INT
		,@DisapprovedAllNum INT
		,@ClosedAllNum INT
		,@DepositMemAllNum INT
		,@DepositAll MONEY
		,@WinlostAll MONEY
		,@BonusAll MONEY
		,@PSPFeeAll MONEY
		,@AdjustmentAll MONEY
		,@TurnoverAll MONEY
		,@WithdrawalAll MONEY
		,@NetWinlostAll MONEY
		,@BannerNum INT
		,@ImageBannerNum INT
		,@FlashBannerNum INT
		,@MediaImageBannerNum INT
		,@MediaFlashBannerNum INT
		,@KioskImageBannerNum INT
		,@KioskFlashBannerNum INT
		,@AffInProMonthNum INT
		,@PendingMonthNum INT
		,@ApprovedMonthNum INT
		,@DisapprovedMonthNum INT
		,@ClosedMonthNum INT
		,@DepositMemMonthNum INT
		,@DepositMonth MONEY
		,@WinlostMonth MONEY
		,@BonusMonth MONEY
		,@PSPFeeMonth MONEY
		,@AdjustmentMonth MONEY
		,@TurnoverMonth MONEY
		,@WithdrawalMonth MONEY
		,@NetWinlostMonth MONEY
		,@LockedAllNum INT
		,@LockedMonthNum INT
	DECLARE @TransType INT
	DECLARE @CurrentDate SMALLDATETIME
	DECLARE @AffNormal TINYINT
		,@AffMedia TINYINT
	--dflag=0 : for all previous months data    
	-- dflag=1 : for current month data    
	DECLARE @tmpCurrency TABLE (
		CurrencyID INT
		,ExRate FLOAT
		)

	SET NOCOUNT ON;

	SELECT @CurrentDate = convert(VARCHAR(10), current_timestamp, 120)

	SELECT @AffNormal = 1
		,@AffMedia = 2

	SELECT @TransType = 202 -- payment request    

	INSERT INTO @tmpCurrency
	SELECT AttributeID
		,0 AS ExRate
	FROM dbo.Aff_f_GetCurrencybyUser(@userID, 1)

	SELECT @PaymentReqNum = sum(1)
	FROM AffTrans af WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH(NOLOCK)
		ON af.AffId = ai.AffId 
	WHERE af.TransType = @TransType 
		AND af.AffCurrency IN (
			SELECT CurrencyID
			FROM @tmpCurrency
		) 
		AND af.STATUS = 'Pending'
		AND ai.TestLevel = 0
		AND ai.STATUS = 'Approved'

	-- all affiliate statc      
	SELECT @PendingAllNum = sum(CASE 
				WHEN STATUS = 'Pending' THEN 1
				ELSE 0
				END)
		,@ApprovedAllNum = sum(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 0 AND IsLocked = 0 THEN 1
				ELSE 0
				END)
		,@DisapprovedAllNum = sum(CASE 
				WHEN STATUS = 'Disapproved' THEN 1
				ELSE 0
				END)
		,@ClosedAllNum = sum(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 1 THEN 1
				ELSE 0
				END)
		,@LockedAllNum = sum(CASE 
				WHEN STATUS = 'Approved' AND IsLocked = 1 THEN 1
				ELSE 0
				END)
		,@AffInProAllNum = sum(1)
		,@AffInProMonthNum = sum(CASE 
				WHEN datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@PendingMonthNum = sum(CASE 
				WHEN STATUS = 'pending' AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@ApprovedMonthNum = sum(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 0 AND IsLocked = 0 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@DisapprovedMonthNum = sum(CASE 
				WHEN STATUS = 'Disapproved' AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@ClosedMonthNum = sum(CASE 
				WHEN STATUS = 'Approved' AND IsClosed = 1 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@LockedMonthNum = sum(CASE 
				WHEN STATUS = 'Approved' AND IsLocked = 1 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
	FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN @tmpCurrency t ON AI.Currency = t.CurrencyID
	WHERE ai.TestLevel = 0

	-- //all banner statc    
	SELECT @BannerNum = sum(CASE 
				WHEN bt.Value IN ('Image', 'Flash') THEN 1
				ELSE 0
				END)
		,@ImageBannerNum = sum(CASE 
				WHEN bt.Value = 'Image' AND b.Type = 1 THEN 1
				ELSE 0
				END)
		,@FlashBannerNum = sum(CASE 
				WHEN bt.Value = 'Flash' AND b.Type = 1 THEN 1
				ELSE 0
				END)
		,@MediaImageBannerNum = sum(CASE 
				WHEN bt.Value = 'Image' AND b.Type = 2 THEN 1
				ELSE 0
				END)
		,@MediaFlashBannerNum = sum(CASE 
				WHEN bt.Value = 'Flash' AND b.Type = 2 THEN 1
				ELSE 0
				END)
		,@KioskImageBannerNum = sum(CASE 
				WHEN bt.Value = 'Image' AND b.Type = 3 THEN 1
				ELSE 0
				END)
		,@KioskFlashBannerNum = sum(CASE 
				WHEN bt.Value = 'Flash' AND b.Type = 3 THEN 1
				ELSE 0
				END)
	FROM Banners b WITH (NOLOCK)
		INNER JOIN BannerTypes bt WITH (NOLOCK) ON b.ImageType = bt.TypeID
	WHERE bt.Type = 'ImageType'

	DECLARE @MaxWinLostDateAffComm SMALLDATETIME
		,@NextMaxWinlostDate SMALLDATETIME

	SELECT @MaxWinLostDateAffComm = max(winlostdate)
	FROM AffCommission WITH (NOLOCK)

	SELECT @NextMaxWinlostDate = dateadd(d, 1, @MaxWinLostDateAffComm)

	--Get statistics of normal affiliate    
	EXEC [AffAdmin_GetMemberStatistics]
		--@AffType = @AffNormal,    
		@UserId = @UserId
		,@DepositAll = @DepositAll OUTPUT
		,@DepositMonth = @DepositMonth OUTPUT
		,@PSPFeeAll = @PSPFeeAll OUTPUT
		,@PSPFeeMonth = @PSPFeeMonth OUTPUT
		,@WinlostAll = @WinlostAll OUTPUT
		,@WinlostMonth = @WinlostMonth OUTPUT
		,@BonusAll = @BonusAll OUTPUT
		,@BonusMonth = @BonusMonth OUTPUT
		,@AdjustmentAll = @AdjustmentAll OUTPUT
		,@AdjustmentMonth = @AdjustmentMonth OUTPUT
		,@TurnoverAll = @TurnoverAll OUTPUT
		,@TurnoverMonth = @TurnoverMonth OUTPUT
		,@NetWinlostAll = @NetWinlostAll OUTPUT
		,@NetWinlostMonth = @NetWinlostMonth OUTPUT
		,@WithdrawalAll = @WithdrawalAll OUTPUT
		,@WithdrawalMonth = @WithdrawalMonth OUTPUT

	SELECT @DepositMemAllNum = sum(CASE 
				WHEN CreatedDate IS NOT NULL THEN 1
				ELSE 0
				END)
		,@DepositMemMonthNum = sum(CASE 
				WHEN datediff(m, m.CreatedDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@MemInProAllNum = count(1)
		,@MemInProMonthNum = sum(CASE 
				WHEN datediff(m, m.RegisteredDate, @CurrentDate) = 0 THEN 1
				ELSE 0
				END)
		,@NonDepositMemMonthNum = sum(CASE 
				WHEN datediff(m, m.RegisteredDate, @CurrentDate) = 0 AND CreatedDate IS NULL THEN 1
				ELSE 0
				END)
	FROM MemberInfo m WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK)
		ON m.AffId = ai.AffId
	WHERE m.IsRemoved = 0
		AND ai.TestLevel = 0

	--final result here    
	SELECT isnull(@PaymentReqNum, 0) AS PaymentReqNum
		,isnull(@AffInProAllNum, 0) AS AffInProAllNum
		,isnull(@PendingAllNum, 0) AS PendingAllNum
		,isnull(@ApprovedAllNum, 0) AS ApprovedAllNum
		,isnull(@DisapprovedAllNum, 0) AS DisapprovedAllNum
		,isnull(@DepositMemAllNum, 0) AS DepositMemAllNum
		,isnull(@ClosedAllNum, 0) AS ClosedAllNum
		,isnull(@DepositAll, 0) AS DepositAll
		,isnull(@WinlostAll, 0) AS WinlostAll
		,isnull(@BonusAll, 0) AS BonusAll
		,isnull(@PSPFeeAll, 0) AS PSPFeeAll
		,isnull(@AdjustmentAll, 0) AS AdjustmentAll
		,isnull(@TurnoverAll, 0) AS TurnoverAll
		,isnull(@WithdrawalAll, 0) AS WithdrawalAll
		,isnull(@NetWinlostAll, 0) AS NetWinlostAll
		,isnull(@BannerNum, 0) AS BannerNum
		,isnull(@ImageBannerNum, 0) AS ImageBannerNum
		,isnull(@FlashBannerNum, 0) AS FlashBannerNum
		,isnull(@MediaImageBannerNum, 0) AS MediaImageBannerNum
		,isnull(@MediaFlashBannerNum, 0) AS MediaFlashBannerNum
		,isnull(@KioskImageBannerNum, 0) AS KioskImageBannerNum
		,isnull(@KioskFlashBannerNum, 0) AS KioskFlashBannerNum
		,isnull(@AffInProMonthNum, 0) AS AffInProMonthNum
		,isnull(@PendingMonthNum, 0) AS PendingMonthNum
		,isnull(@ApprovedMonthNum, 0) AS ApprovedMonthNum
		,isnull(@DisapprovedMonthNum, 0) AS DisapprovedMonthNum
		,isnull(@ClosedMonthNum, 0) AS ClosedMonthNum
		,isnull(@DepositMemMonthNum, 0) AS DepositMemMonthNum
		,isnull(@DepositMonth, 0) AS DepositMonth
		,isnull(@WinlostMonth, 0) AS WinlostMonth
		,isnull(@BonusMonth, 0) AS BonusMonth
		,isnull(@PSPFeeMonth, 0) AS PSPFeeMonth
		,isnull(@AdjustmentMonth, 0) AS AdjustmentMonth
		,isnull(@TurnoverMonth, 0) AS TurnoverMonth
		,isnull(@WithdrawalMonth, 0) AS WithdrawalMonth
		,isnull(@NetWinlostMonth, 0) AS NetWinlostMonth
		,isnull(@LockedAllNum, 0) AS LockedAllNum
		,isnull(@LockedMonthNum, 0) AS LockedMonthNum
		,isnull(@MemInProAllNum, 0) AS MemInProAllNum
		,isnull(@MemInProMonthNum, 0) AS MemInProMonthNum
		,isnull(@NonDepositMemMonthNum, 0) AS NonDepositMemMonthNum
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_HomeGeneralInfo] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_HomeGeneralInfo] TO [vnteam]

