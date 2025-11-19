/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_Monthly_Commission]  
	@MonthDate		SMALLDATETIME,
	@IsForceUpdate	BIT = 0
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Job - Calculate commission monthly

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250102@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250324@Sally: Remove P2P Settings [RedmineID: #219936]
		- 20250403@Sally: Enhance Get BBF by TimeZone [RedmineID: #222352]
		- 20251015@Sally: Enhance Sub-Commission calculation [RedmineID: #241604]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

	SELECT  @FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @LastDayOfMonth  = EOMONTH(@FirstDayOfMonth)

	-- Check month of @MonthDate is completed
	IF @LastDayOfMonth > CURRENT_TIMESTAMP
	BEGIN
		SELECT 'This month is not completed yet!'

		RETURN
	END

	-- Check settings are archived
	IF NOT EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
	BEGIN
		SELECT 'Settings of this month are not archived yet!'

		RETURN
	END

	-- Check job run already
	IF @IsForceUpdate = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.rptAffCommission WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		BEGIN
			SELECT 'Data is already done for this month!'

			RETURN
		END
	END

	-- Process data
		-- Get Data
	BEGIN
		CREATE TABLE #TempCommission
		(
			MonthDate			SMALLDATETIME,
			AffId				INT,
			GroupId				INT,
			ProductId			INT,
			GroupProductId		TINYINT,
			Deposit				MONEY,
			Withdrawal			MONEY,
			Bonus				MONEY,
			Rebate				MONEY,
			Turnover			MONEY,
			Winloss				MONEY,
			Revenue				MONEY,
			-- Fees
			P2PFee				MONEY,
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			DepositFee			MONEY,
			WithdrawalFee		MONEY,
			-- Calculation
			GrossWinloss		MONEY,
			NetWinloss			MONEY,
			NetTurnover			MONEY,
			ActivePlayer		INT,
			QualifiedMember     INT,
			CommissionRate		FLOAT,
			Commission			MONEY,
			StraightCommission	MONEY,
			SubAffCommission	MONEY,
			IsMultiGroupProduct BIT
		)

		-- Uncalculated Months
		INSERT INTO #TempCommission
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			GroupProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Rebate,
			Turnover,
			Winloss,
			Revenue,
			P2PFee,
			PlatFormFee,
			OperationalFee,
			DepositFee,
			WithdrawalFee,
			GrossWinloss,
			NetWinloss,
			NetTurnover,
			ActivePlayer,
			QualifiedMember,
			CommissionRate,
			Commission,
			StraightCommission,
			SubAffCommission,
			IsMultiGroupProduct
		)
		EXEC dbo.Aff_Commission_UnCalc
			@AffIds				= 'all',
			@FromMonthDate		= @FirstDayOfMonth,
			@ToMonthDate		= @LastDayOfMonth,
			@ProductIds			= '0',
			@BaseCurrency		= 0,
			@IsSumAll			= 0,
			@IsForJob           = 1,
			@GetRowTotalOnly	= 0
	END

		-- Remove invalid data
	DELETE tc
	FROM #TempCommission tc
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON tc.AffId = ai.AffId
	WHERE ai.Status <> 'Approved' OR ai.IsClosed = 1

	-- Import data
	IF @IsForceUpdate = 1
	BEGIN
		DELETE dbo.rptAffCommission WITH (ROWLOCK, UPDLOCK)
		WHERE MonthDate = @LastDayOfMonth

		DELETE dbo.rptAffCommissionDetail WITH (ROWLOCK, UPDLOCK)
		WHERE MonthDate = @LastDayOfMonth

		DELETE dbo.rptAffMonthly WITH (ROWLOCK, UPDLOCK)
		WHERE MonthDate = @LastDayOfMonth

		DELETE dbo.AffTrans WITH (ROWLOCK, UPDLOCK)
		WHERE TransDate = @LastDayOfMonth AND TransType IN (201, 204, 205) -- Commission Type
	END

	DECLARE @AffCurrency INT, @AffRate FLOAT
	SELECT  @AffCurrency = CONVERT(INT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'
	SELECt  @AffRate = Rate FROM dbo.Aff_f_ExchangeRate_Sel(@LastDayOfMonth, @AffCurrency, 0)

	INSERT INTO dbo.rptAffCommission
	(
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Rebate,
		Turnover,
		Winloss,
		Revenue,
		GrossWinloss,
		NetWinloss,
		NetTurnover,
		ActivePlayer,
		QualifiedMember,
		P2PFee,
		PlatFormFee,
		OperationalFee,
		DepositFee,
		WithdrawalFee,
		CommissionRate
	)
	SELECT
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Rebate,
		Turnover,
		Winloss,
		Revenue,
		GrossWinloss,
		NetWinloss,
		NetTurnover,
		ActivePlayer,
		QualifiedMember,
		P2PFee,
		PlatFormFee,
		OperationalFee,
		DepositFee,
		WithdrawalFee,
		CommissionRate
	FROM #TempCommission
	WHERE ProductId = 0

	INSERT INTO dbo.rptAffCommissionDetail
	(
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		GroupProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Rebate,
		Turnover,
		Winloss,
		Revenue,
		GrossWinloss,
		NetWinloss,
		NetTurnover,
		ActivePlayer,
		QualifiedMember,
		P2PFee,
		PlatFormFee,
		OperationalFee,
		DepositFee,
		WithdrawalFee,
		CommissionRate
	)
	SELECT
		MonthDate,
		AffId,
		GroupId,
		0 AS ProductId,
		GroupProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Rebate,
		Turnover,
		Winloss,
		Revenue,
		GrossWinloss,
		NetWinloss,
		NetTurnover,
		ActivePlayer,
		QualifiedMember,
		P2PFee,
		PlatFormFee,
		OperationalFee,
		DepositFee,
		WithdrawalFee,
		CommissionRate
	FROM #TempCommission
	WHERE ProductId = -1

	INSERT INTO dbo.rptAffMonthly
	(
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Turnover,
		Winloss,
		Revenue
	)
	SELECT
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Turnover,
		Winloss,
		Revenue
	FROM #TempCommission
	WHERE ProductId > 0

	INSERT INTO dbo.AffTrans
	(
		AffId,
		TransDate,
		CompletedDate,
		Amount,
		Status,
		Description,
		Creator,
		TransType,
		AffCurrency,
		AffRate,
		WinlostDate
	)
	SELECT
		c.AffId,
		c.MonthDate AS TransDate,
		GETDATE() AS CompletedDate,
		t.Amount,
		'Approved' AS Status,
		'Monthly Earning' AS Description,
		148 AS Creator,
		t.TransType,
		@AffCurrency,
		@AffRate,
		c.MonthDate
	FROM #TempCommission c
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON c.GroupId = cg.GroupId
		INNER JOIN dbo.CommGroupHistory cgh WITH (NOLOCK) ON c.GroupId = cgh.GroupId AND cgh.MonthDate = @LastDayOfMonth
		CROSS APPLY (
			SELECT 201 AS TransType, Commission AS Amount
			WHERE cg.GroupTypeId <> 3 -- Exclude CPA Deals
			UNION ALL
			SELECT 204, SubAffCommission
			WHERE (cg.GroupTypeId <> 1 AND cgh.IsSubCommRate = 1) OR cg.GroupTypeId = 1 -- Include Sub-Aff Commission for CPA/Hyrid Deals with Flag SubCommrate =1
		) t
	WHERE c.ProductId = 0

	-- Update Commission Date
	DECLARE @LaunchDate SMALLDATETIME, @LastCommDate SMALLDATETIME
	SELECT  @LaunchDate		= CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LaunchDate'
	SELECT  @LastCommDate	= CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	IF @LastDayOfMonth >= DATEADD(DAY, -1, @LaunchDate) AND @LastDayOfMonth > @LastCommDate
		UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
		SET SValue = CONVERT(VARCHAR(10), @LastDayOfMonth, 120)
		WHERE SName = 'AFF_CommissionDate'
END
GO