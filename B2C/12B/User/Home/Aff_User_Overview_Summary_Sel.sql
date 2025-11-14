/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE  PROCEDURE [dbo].[Aff_User_Overview_Summary_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@IsGetMonthly	BIT = 1
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Summary

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241226@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250313@Sally: Missing data on total FDM's Deposit by month [RedmineID: #219974]
		- 20250313@Sally: Get Rate for  FDM's Deposit [RedmineID: #219974]
		- 20250416@Sally: Change the data retrieval method for Deposit [RedmineID: #224116]
		- 20250401@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]
		- 20250912@Sally: Get NetGGR data [RedmineID: #238476]
		- 20250929@Sophia: Add TotalClick and UniqueClick columns [RedmineID: #239549]
		- 20251002@Sophia: Implement hybrid approach using rptMemberDaily for historical data and DepositInfo for recent data based on commission date boundary [RedmineID: #239737]
		- 20251022@Sophia: Add IsExcluded = 0 condition to filter excluded clicks [RedmineID: #241768]
		- 20251118@AI: Add date-range mode, CPA metrics (Approved/Tentative/Qualified), and GroupType detection [RedmineID: #202506]

	Notes:
	  - @IsGetMonthly = 1: Monthly mode (uses commission engines); = 0: Date-range mode (direct rptMemberDaily)
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)
	  - Data separation: rptMemberDaily for historical data (before commission boundary), DepositInfo for recent data (after commission boundary)
	  - Commission boundary = @CommissionBoundary = AFF_CommissionDate + 1 day
	  - CPA: StatusId 2=Eligible, 3=Settled; Quota from current open-ended AffGroupHistory row
*/

BEGIN
	SET NOCOUNT ON
	
	-- Date range normalization
	DECLARE @BeginOfMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	IF @IsGetMonthly = 1
	BEGIN
		-- Monthly mode: normalize to month boundaries
		SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0)
		SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @BeginOfMonth)
	END
	ELSE
	BEGIN
		-- Date-range mode: use supplied dates directly
		SELECT @BeginOfMonth = @FromDate, @ToNextMonth = @ToDate
	END

	-- Pre-calculate DATE variables for WinlostDate index optimization
	DECLARE @WinlostDateFrom DATE, @WinlostDateTo DATE
	SELECT @WinlostDateFrom = DATEADD(DAY, -1, CONVERT(DATE, @BeginOfMonth))
	SELECT @WinlostDateTo = @ToNextMonth

	-- Calculate commission date boundary for data separation (commission date + 1 day)
	DECLARE @CommissionBoundary SMALLDATETIME
	SELECT @CommissionBoundary = DATEADD(DAY, 1, CONVERT(SMALLDATETIME, SValue)) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	-- Click Statistics
	BEGIN
		DECLARE @TotalClick INT, @UniqueClick INT;
		
		DECLARE @ArchiveDate SMALLDATETIME;
		SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics'); -- GMT-4, Date only
	
		-- Convert from GMT+8 to GMT-4 for comparison with ClickStatistics.Date
		DECLARE @FromDate_GMT4 DATETIME, @ToDate_GMT4 DATETIME;
		SELECT @FromDate_GMT4 = DATEADD(HOUR, -12, CAST(@BeginOfMonth AS DATETIME)), -- GMT+8 to GMT-4
			   @ToDate_GMT4 = DATEADD(HOUR, -12, CAST(@ToNextMonth AS DATETIME)); -- GMT+8 to GMT-4
	
		CREATE TABLE #ClickData (TotalClick INT DEFAULT(0), IP VARCHAR(25));
		
		-- Current data
		IF CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate
		BEGIN
			INSERT INTO #ClickData (TotalClick, IP)
			SELECT COUNT(1) AS TotalClick, IP
			FROM dbo.ClickStatistics WITH (NOLOCK)
			WHERE AffId = @AffID
				AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4
				AND [Date] >= CASE WHEN CONVERT(DATE, @FromDate_GMT4) > @ArchiveDate 
							  THEN CONVERT(DATE, @FromDate_GMT4) 
							  ELSE DATEADD(Day, 1, @ArchiveDate) END
				AND [Date] < DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4))
				AND IsExcluded = 0
			GROUP BY IP;
		END;

		-- Archived data
		IF CONVERT(DATE, @FromDate_GMT4) <= @ArchiveDate
		BEGIN
			INSERT INTO #ClickData (TotalClick, IP)
			SELECT COUNT(1) AS TotalClick, IP
			FROM dbo.ClickStatistics_bk WITH (NOLOCK)
			WHERE AffId = @AffID
				AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4
				AND [Date] >= CONVERT(DATE, @FromDate_GMT4)
				AND [Date] < CASE WHEN CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate 
							 THEN DATEADD(Day, 1, @ArchiveDate) 
							 ELSE DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4)) END
				AND IsExcluded = 0
			GROUP BY IP;
		END;

		SELECT @TotalClick = SUM(TotalClick),
			   @UniqueClick = COUNT(DISTINCT IP)
		FROM #ClickData;

		DROP TABLE #ClickData;
	END;

	-- Total Signup/Deposited Members
	BEGIN
		DECLARE @Signups INT, @DepositedMembers INT, @FDMDeposit MONEY
		
		SELECT  @Signups		   = COUNT(CASE WHEN RegisteredDate >= @BeginOfMonth AND RegisteredDate < @ToNextMonth THEN 1 ELSE NULL END)
				,@DepositedMembers = COUNT(CASE WHEN FirstDepositDate >= @BeginOfMonth AND FirstDepositDate < @ToNextMonth THEN 1 ELSE NULL END)			
		FROM dbo.MemberInfo m WITH (NOLOCK)
		WHERE AffId = @AffId

		SELECT @FDMDeposit = SUM(fd.FirstDepositAmount * ex.Rate)
		FROM (
			SELECT Currency
				,SUM(ISNULL(FirstDepositAmount,0)) AS FirstDepositAmount
				,CONVERT(DATE, EOMONTH(FirstDepositDate)) AS MonthDate
			FROM dbo.MemberInfo r WITH (NOLOCK)
			WHERE AffId = @AffId
				AND FirstDepositDate >= @BeginOfMonth 
				AND FirstDepositDate < @ToNextMonth
			GROUP BY Currency, CONVERT(DATE, EOMONTH(FirstDepositDate))
		) fd
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON fd.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(fd.MonthDate, ISNULL(t.ExchangeId, fd.Currency), @BaseExchangeId) ex
	END

	-- Total Deposit - Conditional hybrid approach
	BEGIN
		DECLARE @Deposit MONEY
		
		-- Check if @BeginOfMonth is before commission boundary
		IF @BeginOfMonth < @CommissionBoundary
		BEGIN
			-- Use rptMemberDaily only for historical data with currency grouping optimization
			SELECT @Deposit = SUM(rd.Deposit * ex.Rate)
			FROM (
				SELECT Currency
					,SUM(ISNULL(Deposit, 0)) AS Deposit
					,CONVERT(DATE, EOMONTH(WinlostDate)) AS MonthDate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate >= @BeginOfMonth 
					AND r.WinlostDate < @ToNextMonth
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
						WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
					)
				GROUP BY Currency, CONVERT(DATE, EOMONTH(WinlostDate))
			) rd
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON rd.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(rd.MonthDate, ISNULL(t.ExchangeId, rd.Currency), @BaseExchangeId) ex
		END
		ELSE
		BEGIN
			-- Use live DepositInfo for recent months with currency grouping optimization
			SELECT @Deposit = SUM(dd.ActualDeposit * ex.Rate)
			FROM (
				SELECT mi.Currency
					,SUM(d.ActualDeposit * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS ActualDeposit
					,CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, d.CreateTime))) AS MonthDate
				FROM bodb_12B.dbo.DepositInfo d WITH(NOLOCK)
					INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON d.CustId = mi.CustId
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
					LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeId
				WHERE mi.AffId = @AffId
					AND d.Status = 3  -- Approved deposits only
					AND d.WinlostDate BETWEEN @WinlostDateFrom AND @WinlostDateTo  -- Use WinlostDate index with pre-calculated DATE variables
					AND DATEADD(HOUR, 8, d.CreateTime) >= @BeginOfMonth  -- Within month range (GMT+8)
					AND DATEADD(HOUR, 8, d.CreateTime) < @ToNextMonth  -- Within month range (GMT+8)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = d.CustId 
						AND CAST(DATEADD(HOUR, 8, d.CreateTime) AS DATE) BETWEEN mr.FromDate AND mr.ToDate  -- Convert to GMT+8 for comparison
					)
				GROUP BY mi.Currency, CONVERT(DATE, EOMONTH(DATEADD(HOUR, 8, d.CreateTime)))
			) dd
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON dd.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(dd.MonthDate, ISNULL(t.ExchangeId, dd.Currency), @BaseExchangeId) ex
		END
	END

	-- Balance Brought Forward
	BEGIN
		DECLARE @BBF MONEY
		SELECT  @BBF = SUM(Amount)
		FROM dbo.AffTrans WITH (NOLOCK)
		WHERE AffId = @AffId
			AND WinlostDate < @ToNextMonth
			AND Status IN ('Pending', 'Approved', 'Completed')
	END

	-- GroupType Detection
	BEGIN
		DECLARE @GroupTypeName VARCHAR(20) = 'Hybrid'
		
		-- Check if affiliate has any non-CPA groups (GroupTypeId <> 3) in date range
		DECLARE @HasNonCPA BIT = 0, @HasNonRevenue BIT = 0
		
		IF EXISTS (
			SELECT 1 FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON agh.GroupId = cg.GroupId
			WHERE agh.AffId = @AffId
				AND agh.FromDate < @ToNextMonth
				AND agh.ToDate >= @BeginOfMonth
				AND cg.GroupTypeId <> 3  -- Not CPA
		)
			SET @HasNonCPA = 1
		
		IF EXISTS (
			SELECT 1 FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON agh.GroupId = cg.GroupId
			WHERE agh.AffId = @AffId
				AND agh.FromDate < @ToNextMonth
				AND agh.ToDate >= @BeginOfMonth
				AND cg.GroupTypeId <> 1  -- Not Revenue Share
		)
			SET @HasNonRevenue = 1
		
		IF @HasNonCPA = 0
			SET @GroupTypeName = 'CPA'
		ELSE IF @HasNonRevenue = 0
			SET @GroupTypeName = 'Revenue'
	END

	-- CPA Metrics
	BEGIN
		DECLARE @ApprovedCPAAmount MONEY = 0, @TentativeCPAAmount MONEY = 0, @QualifiedMemberCPA INT = 0
		DECLARE @Quota INT, @RemainQuota INT, @CurrentGroupId INT
		DECLARE @CurrentDate SMALLDATETIME = GETDATE()
		
		-- Get current group and quota from open-ended history row
		SELECT TOP 1 @CurrentGroupId = agh.GroupId,
			@Quota = CASE WHEN cg.Quota = 0 THEN NULL ELSE cg.Quota END
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON agh.GroupId = cg.GroupId
		WHERE agh.AffId = @AffId
			AND agh.ToDate = '9999-12-31'
		ORDER BY agh.FromDate DESC
		
		IF @CurrentGroupId IS NOT NULL
		BEGIN
			-- Approved CPA (StatusId=3, CPADate in range)
			SELECT @ApprovedCPAAmount = SUM(CPAAmount)
			FROM dbo.MemberCPA WITH (NOLOCK)
			WHERE AffId = @AffId
				AND GroupId = @CurrentGroupId
				AND StatusId = 3
				AND CPADate >= @BeginOfMonth
				AND CPADate < @ToNextMonth
			
			-- Calculate remaining quota (all-time consumption)
			DECLARE @SettledCount INT
			SELECT @SettledCount = COUNT(1)
			FROM dbo.MemberCPA WITH (NOLOCK)
			WHERE AffId = @AffId
				AND GroupId = @CurrentGroupId
				AND StatusId = 3
			
			IF @Quota IS NULL
				SET @RemainQuota = 2147483647  -- Unlimited
			ELSE
				SET @RemainQuota = @Quota - @SettledCount
			
			-- Qualified CPA (current month only: add eligible candidates)
			IF MONTH(@ToNextMonth) = MONTH(DATEADD(DAY, 1, @CurrentDate))  -- Current month check
			BEGIN
				DECLARE @EligibleCount INT
				SELECT @EligibleCount = COUNT(1)
				FROM dbo.MemberCPA WITH (NOLOCK)
				WHERE AffId = @AffId
					AND GroupId = @CurrentGroupId
					AND StatusId = 2  -- Eligible
					AND HoldingQualifiedDate <= @ToNextMonth
				
				SET @QualifiedMemberCPA = @SettledCount + CASE WHEN @RemainQuota < @EligibleCount THEN @RemainQuota ELSE @EligibleCount END
				
				-- Tentative CPA: sum top N eligible by HoldingQualifiedDate
				SELECT @TentativeCPAAmount = SUM(CPAAmount)
				FROM (
					SELECT TOP (@RemainQuota) CPAAmount
					FROM dbo.MemberCPA WITH (NOLOCK)
					WHERE AffId = @AffId
						AND GroupId = @CurrentGroupId
						AND StatusId = 2
						AND HoldingQualifiedDate <= @ToNextMonth
					ORDER BY HoldingQualifiedDate ASC, FirstDepositDate ASC, MemberCPA_ID ASC
				) AS TopEligible
			END
			ELSE
			BEGIN
				-- Past months: only settled count
				SELECT @QualifiedMemberCPA = COUNT(1)
				FROM dbo.MemberCPA WITH (NOLOCK)
				WHERE AffId = @AffId
					AND GroupId = @CurrentGroupId
					AND StatusId = 3
					AND CPADate >= @BeginOfMonth
					AND CPADate < @ToNextMonth
			END
		END
	END

	-- Active Players, Turnover, Deposit, Commission, QualifiedMember
	BEGIN
		DECLARE @NoOfSubAff INT, @ActivePlayers INT, @QualifiedMember INT, @Turnover MONEY, @Commission MONEY, @SubAffCommission MONEY, @NetGGR MONEY

		SELECT @NoOfSubAff = COUNT(1)
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ParentAffId = @AffId
			AND Status = 'Approved'
			AND IsClosed = 0
			AND ApprovedDate >= @BeginOfMonth AND ApprovedDate < @ToNextMonth

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

		DECLARE @MaxCommDate SMALLDATETIME, @AffIds VARCHAR(MAX)
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		-- Revenue Share: Monthly mode uses commission engines
		IF @IsGetMonthly = 1
		BEGIN
			IF @BeginOfMonth > @MaxCommDate
			BEGIN
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
					@AffIds				= @AffIds,
					@FromMonthDate		= @BeginOfMonth,
					@ToMonthDate		= @BeginOfMonth,
					@ProductIds			= '0',
					@BaseCurrency		= @BaseCurrency,
					@IsSumAll			= 1,
					@GetRowTotalOnly	= 1
			END
			ELSE
			BEGIN
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
						@AffIds				= @AffIds,
						@FromMonthDate		= @BeginOfMonth,
						@ToMonthDate		= @BeginOfMonth,
						@ProductIds			= '0',
						@BaseCurrency		= @BaseCurrency,
						@IsSumAll			= 1,
						@GetRowTotalOnly	= 1
			END
		END
		ELSE
		BEGIN
			-- Date-range mode: Direct rptMemberDaily aggregation
			CREATE TABLE #DataMemberDaily (
				MonthDate SMALLDATETIME,
				AffId INT,
				Currency INT,
				CustId INT,
				ProductId INT,
				Turnover MONEY,
				Winloss MONEY,
				Bonus MONEY,
				Rebate MONEY
			)
			
			INSERT INTO #DataMemberDaily (MonthDate, AffId, Currency, CustId, ProductId, Turnover, Winloss, Bonus, Rebate)
			SELECT 
				CONVERT(DATE, EOMONTH(r.WinlostDate)) AS MonthDate,
				r.AffId,
				r.Currency,
				r.CustId,
				r.ProductId,
				SUM(ISNULL(r.Turnover, 0)) AS Turnover,
				SUM(ISNULL(r.Winloss, 0)) AS Winloss,
				SUM(ISNULL(r.Bonus, 0)) AS Bonus,
				SUM(ISNULL(r.Rebate, 0)) AS Rebate
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			WHERE r.AffId = @AffId
				AND r.WinlostDate >= @BeginOfMonth
				AND r.WinlostDate < @ToNextMonth
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.CustId = r.CustId
						AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY CONVERT(DATE, EOMONTH(r.WinlostDate)), r.AffId, r.Currency, r.CustId, r.ProductId
			
			-- Get QM Turnover from group history and calculate metrics
			INSERT INTO #TempCommission (MonthDate, AffId, Turnover, NetWinloss, ActivePlayer, QualifiedMember)
			SELECT 
				dmd.MonthDate,
				dmd.AffId,
				SUM(dmd.Turnover * ex.Rate) AS Turnover,
				SUM((dmd.Winloss - dmd.Bonus - dmd.Rebate) * ex.Rate) AS NetWinloss,
				COUNT(DISTINCT CASE WHEN dmd.ProductId > 0 THEN dmd.CustId END) AS ActivePlayer,
				COUNT(DISTINCT CASE 
					WHEN dmd.ProductId > 0 AND SUM(dmd.Turnover) >= ISNULL(cgh.QMTurnover, 0) 
					THEN dmd.CustId 
				END) AS QualifiedMember
			FROM #DataMemberDaily dmd
			LEFT JOIN dbo.AffGroupHistory agh WITH (NOLOCK) 
				ON agh.AffId = dmd.AffId 
				AND agh.FromDate <= dmd.MonthDate 
				AND agh.ToDate >= dmd.MonthDate
			LEFT JOIN dbo.CommGroupHistory cgh WITH (NOLOCK) 
				ON cgh.GroupId = agh.GroupId 
				AND cgh.MonthDate = dmd.MonthDate
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON dmd.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(dmd.MonthDate, ISNULL(t.ExchangeId, dmd.Currency), @BaseExchangeId) ex
			GROUP BY dmd.MonthDate, dmd.AffId
			
			DROP TABLE #DataMemberDaily
		END

		SELECT
			@ActivePlayers		= SUM(ISNULL(ActivePlayer, 0))
			,@QualifiedMember	= SUM(ISNULL(QualifiedMember, 0))
			,@Turnover			= SUM(ISNULL(Turnover, 0))
			,@Commission		= SUM(ISNULL(Commission, 0))
			,@SubAffCommission	= SUM(ISNULL(SubAffCommission, 0))
			,@NetGGR			= SUM(ISNULL(NetWinloss, 0))
		FROM #TempCommission

		DROP TABLE #TempCommission
	END

	-- Return result
	BEGIN
		SELECT
			ISNULL(@Signups, 0)				AS Signups
			,ISNULL(@DepositedMembers, 0)	AS DepositedMembers
			,ISNULL(@BBF, 0)				AS BalanceBroughtForward
			,ISNULL(@ActivePlayers, 0)		AS ActivePlayers
			,ISNULL(@QualifiedMember, 0)	AS QualifiedMember
			,ISNULL(@Turnover, 0)			AS Turnover
			,ISNULL(@Deposit, 0)			AS Deposit
			,ISNULL(@Commission, 0)			AS Commission
			,ISNULL(@NoOfSubAff, 0)			AS NoOfSubAff
			,ISNULL(@SubAffCommission, 0)	AS SubAffCommission
			,ISNULL(@FDMDeposit, 0)			AS FDMDeposit
			,ISNULL(@NetGGR, 0)				AS NetGGR
			,ISNULL(@TotalClick, 0)			AS TotalClick
			,ISNULL(@UniqueClick, 0)			AS UniqueClick
			,ISNULL(@ApprovedCPAAmount, 0)	AS ApprovedCPAAmount
			,ISNULL(@TentativeCPAAmount, 0)	AS TentativeCPAAmount
			,ISNULL(@QualifiedMemberCPA, 0)	AS QualifiedMemberCPA
			,@GroupTypeName					AS GroupType
	END
END
GO