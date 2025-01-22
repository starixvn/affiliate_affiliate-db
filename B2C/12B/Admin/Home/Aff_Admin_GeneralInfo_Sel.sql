/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_GeneralInfo_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Home page overview

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241226@Sally: Apply QM Turnover [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfCurrentMonth SMALLDATETIME, @LastOfCurrentMonth SMALLDATETIME
	SELECT	@BeginOfCurrentMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	SELECT	@LastOfCurrentMonth = DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfCurrentMonth))

	-- member statistics
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(DATE, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		CREATE TABLE #TempCommission
		(
			MonthDate			SMALLDATETIME,
			AffId				INT,
			GroupId				INT,
			ProductId			INT,
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
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= CONVERT(DATE, GETDATE())

			INSERT INTO #TempCommission
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
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 1
		END

		-- Calculated Months
		BEGIN
			SELECT	@tempFromDate	= dbo.Aff_f_GetMinReportDate(0),
					@tempToDate		= @MaxCommDate

			INSERT INTO #TempCommission
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
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= 'all',
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END
	END

	SELECT
		-- payment
		PaymentReqNum,
		-- banner
		BannerNum,
		PlayerBannerNum,
		AffiliateBannerNum,
		-- all
		AffInProAllNum,
		PendingAllNum,
		ApprovedAllNum,
		DisapprovedAllNum,
		SuspendedAllNum,
		MemAllNum,
		DepositMemAllNum,
		MemAllNum - DepositMemAllNum AS NonDepositMemAllNum,
		DepositAll,
		GGRAll,
		BonusAll,
		RebateAll,
		PSPFeeAll,
		AdjustmentAll,
		NetWinlostAll,
		-- current month
		AffInProMonthNum,
		PendingMonthNum,
		ApprovedMonthNum,
		DisapprovedMonthNum,
		SuspendedMonthNum,
		MemMonthNum,
		DepositMemMonthNum,
		MemMonthNum - DepositMemMonthNum AS NonDepositMemMonthNum,
		DepositMonth,
		GGRMonth,
		BonusMonth,
		RebateMonth,
		PSPFeeMonth,
		AdjustmentMonth,
		NetWinlostMonth
	FROM
	(
		SELECT
			SUM(ISNULL(Deposit, 0))		AS DepositAll,
			SUM(ISNULL(Bonus, 0))		AS BonusAll,
			SUM(ISNULL(Rebate, 0))		AS RebateAll,
			SUM(-ISNULL(Winloss, 0) + ISNULL(Revenue, 0))			AS GGRAll,
			SUM(ISNULL(DepositFee, 0) + ISNULL(WithdrawalFee, 0))	AS PSPFeeAll,
			0 AS AdjustmentAll,
			SUM(ISNULL(NetWinloss, 0))	AS NetWinlostAll,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Deposit, 0) ELSE 0 END)		AS DepositMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Bonus, 0) ELSE 0 END)			AS BonusMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Rebate, 0) ELSE 0 END)		AS RebateMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN -ISNULL(Winloss, 0) + ISNULL(Revenue, 0) ELSE 0 END)			AS GGRMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(DepositFee, 0) + ISNULL(WithdrawalFee, 0) ELSE 0 END)	AS PSPFeeMonth,
			0 AS AdjustmentMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(NetWinloss, 0) ELSE 0 END)	AS NetWinlostMonth
		FROM #TempCommission
	) AS memberStatistics

		-- banner statistics
		CROSS JOIN 
		(
			SELECT
				COUNT(1) AS BannerNum,
				COUNT(CASE WHEN TargetId = 1 THEN 1 ELSE NULL END) AS PlayerBannerNum,
				COUNT(CASE WHEN TargetId = 2 THEN 1 ELSE NULL END) AS AffiliateBannerNum
			FROM dbo.MediaGallery WITH (NOLOCK)
			WHERE ImageType = 'Image'
		) AS bannerStatistics
		
		-- affiliate statistics
		CROSS JOIN
		(
			SELECT
				-- total
				SUM(Total)			AS AffInProAllNum,
				SUM(Pending)		AS PendingAllNum,
				SUM(Approved)		AS ApprovedAllNum,
				SUM(Disapproved)	AS DisapprovedAllNum,
				SUM(Suspended)		AS SuspendedAllNum,
				-- current month
				SUM(CASE WHEN CurrentMonth = 1 THEN Total		ELSE 0 END) AS AffInProMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Pending		ELSE 0 END) AS PendingMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Approved	ELSE 0 END) AS ApprovedMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Disapproved ELSE 0 END) AS DisapprovedMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Suspended	ELSE 0 END) AS SuspendedMonthNum
			FROM
			(
				SELECT
					CASE WHEN RegisteredDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END AS CurrentMonth,
					SUM(1) AS Total,
					SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS Pending,
					SUM(CASE WHEN status = 'Disapproved' THEN 1 ELSE 0 END) AS Disapproved,
					SUM(CASE WHEN status = 'Approved' AND IsClosed = 0 AND IsRejected = 0 THEN 1 ELSE 0 END) AS Approved,
					SUM(CASE WHEN status = 'Approved' AND IsClosed = 0 AND IsRejected = 1 THEN 1 ELSE 0 END) AS Suspended
				FROM dbo.AffInfo WITH (NOLOCK)
				GROUP BY
					CASE WHEN RegisteredDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END
			) AS a
		) AS affiliateStatistics

		-- deposit members
		CROSS JOIN
		(
			SELECT
				COUNT(1)			AS MemAllNum,
				COUNT(FirstDepositDate)	AS DepositMemAllNum,

				COUNT(CASE WHEN RegisteredDate >= @BeginOfCurrentMonth AND RegisteredDate < DATEADD(DAY, 1, @LastOfCurrentMonth)
								OR FirstDepositDate >= @BeginOfCurrentMonth AND FirstDepositDate < DATEADD(DAY, 1, @LastOfCurrentMonth)
							THEN 1 ELSE NULL END) AS MemMonthNum,
				COUNT(CASE WHEN FirstDepositDate >= @BeginOfCurrentMonth AND FirstDepositDate < DATEADD(DAY, 1, @LastOfCurrentMonth)
							THEN 1 ELSE NULL END) AS DepositMemMonthNum
			FROM dbo.MemberInfo WITH (NOLOCK)
		) AS depositMembers

		-- payment requests
		CROSS JOIN
		(
			SELECT SUM(1) AS PaymentReqNum
			FROM dbo.AffTrans WITH (NOLOCK)
			WHERE TransType = 202 AND Status = 'Pending'
		) AS paymentRequests

	DROP TABLE #TempCommission
END
GO