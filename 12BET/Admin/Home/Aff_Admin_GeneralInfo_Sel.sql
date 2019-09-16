/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_GeneralInfo_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Home page overview

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BeginOfCurrentMonth SMALLDATETIME, @LastOfCurrentMonth SMALLDATETIME
	SELECT	@BeginOfCurrentMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	SELECT	@LastOfCurrentMonth = DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfCurrentMonth))

	-- member statistics
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		CREATE TABLE #TempCommission
		(
			MonthDate				SMALLDATETIME,
			AffId					INT,
			GroupId					INT,
			ProductId				INT,
			Deposit					MONEY,
			Withdrawal				MONEY,
			Bonus					MONEY,
			Turnover				MONEY,
			Winloss					MONEY,
			AWinloss				MONEY,
			AComm					MONEY,
			-- Fees
			PlatFormFee				MONEY,
			OperationalFee			MONEY,
			BankingFee				MONEY,
			ExchangeWinlossShare	MONEY,
			ExchangeCommShare		MONEY,
			-- Calculation
			GrossWinloss			MONEY,
			NetWinloss				MONEY,
			ActivePlayer			INT,
			QualifiedMember			INT,
			QMTurnover				MONEY,
			CommissionRate			FLOAT,
			Commission				MONEY
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
				Turnover,
				Winloss,
				AWinloss,
				AComm,
				PlatFormFee,
				OperationalFee,
				BankingFee,
				ExchangeWinlossShare,
				ExchangeCommShare,
				GrossWinloss,
				NetWinloss,
				ActivePlayer,
				QualifiedMember,
				QMTurnOver,
				CommissionRate,
				Commission
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
				Turnover,
				Winloss,
				AWinloss,
				AComm,
				PlatFormFee,
				OperationalFee,
				BankingFee,
				ExchangeWinlossShare,
				ExchangeCommShare,
				GrossWinloss,
				NetWinloss,
				ActivePlayer,
				QualifiedMember,
				QMTurnOver,
				CommissionRate,
				Commission
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
		ImageBannerNum,
		FlashBannerNum,
		TextBannerNum,
		-- all
		AffInProAllNum,
		PendingAllNum,
		ApprovedAllNum,
		DisapprovedAllNum,
		DepositMemAllNum,
		ClosedAllNum,
		DepositAll,
		WinlostAll,
		BonusAll,
		PSPFeeAll,
		AdjustmentAll,
		NetWinlostAll,
		-- current month
		AffInProMonthNum,
		PendingMonthNum,
		ApprovedMonthNum,
		DisapprovedMonthNum,
		DepositMemMonthNum,
		ClosedMonthNum,
		DepositMonth,
		WinlostMonth,
		BonusMonth,
		PSPFeeMonth,
		AdjustmentMonth,
		NetWinlostMonth
	FROM
	(
		SELECT
			SUM(ISNULL(Deposit, 0))		AS DepositAll,
			SUM(ISNULL(Winloss, 0))		AS WinlostAll,
			SUM(ISNULL(Bonus, 0))		AS BonusAll,
			SUM(ISNULL(BankingFee, 0))	AS PSPFeeAll,
			0 AS AdjustmentAll,
			SUM(ISNULL(NetWinloss, 0))	AS NetWinlostAll,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Deposit, 0) ELSE 0 END)		AS DepositMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Winloss, 0) ELSE 0 END)		AS WinlostMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(Bonus, 0) ELSE 0 END)			AS BonusMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(BankingFee, 0) ELSE 0 END)	AS PSPFeeMonth,
			0 AS AdjustmentMonth,
			SUM(CASE WHEN MonthDate = @LastOfCurrentMonth THEN ISNULL(NetWinloss, 0) ELSE 0 END)	AS NetWinlostMonth
		FROM #TempCommission
	) AS memberStatistics

		-- banner statistics
		CROSS JOIN 
		(
			SELECT
				SUM(CASE WHEN ImageType IN ('Image','Flash') THEN 1 ELSE 0 END) AS BannerNum,
				SUM(CASE WHEN ImageType = 'Image' THEN 1 ELSE 0 END)			AS ImageBannerNum,
				SUM(CASE WHEN ImageType = 'Flash' THEN 1 ELSE 0 END)			AS FlashBannerNum,
				SUM(CASE WHEN ImageType = 'Text' THEN 1 ELSE 0 END)				AS TextBannerNum
			FROM dbo.Banners_1 WITH (NOLOCK)
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
				SUM(Closed)			AS ClosedAllNum,
				-- current month
				SUM(CASE WHEN CurrentMonth = 1 THEN Total		ELSE 0 END) AS AffInProMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Pending		ELSE 0 END) AS PendingMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Approved	ELSE 0 END) AS ApprovedMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Disapproved ELSE 0 END) AS DisapprovedMonthNum,
				SUM(CASE WHEN CurrentMonth = 1 THEN Closed		ELSE 0 END) AS ClosedMonthNum
			FROM
			(
				SELECT
					CASE WHEN RegisteredDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END AS CurrentMonth,
					SUM(1) AS Total,
					SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS Pending,
					SUM(CASE WHEN status = 'Approved' AND IsClosed = 0 THEN 1 ELSE 0 END) AS Approved,
					SUM(CASE WHEN status = 'Disapproved' THEN 1 ELSE 0 END) AS Disapproved,
					SUM(CASE WHEN status = 'Approved' AND IsClosed = 1 THEN 1 ELSE 0 END) AS Closed
				FROM dbo.AffInfo WITH (NOLOCK)
				GROUP BY
					CASE WHEN RegisteredDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END
			) AS a
		) AS affiliateStatistics

		-- deposit members
		CROSS JOIN
		(
			SELECT
				SUM(1) AS DepositMemAllNum,
				SUM(CASE WHEN CreatedDate < @BeginOfCurrentMonth THEN 0 ELSE 1 END) AS DepositMemMonthNum
			FROM dbo.MemberInfo WITH (NOLOCK)
			WHERE IsRemoved = 0
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