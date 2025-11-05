/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE  PROCEDURE [dbo].[Aff_User_Overview_Summary_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME = NULL
	,@BaseCurrency	INT = 0
	,@IsGetMonthly	BIT = 1
	,@FromDate		SMALLDATETIME = NULL
	,@ToDate		SMALLDATETIME = NULL
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
		- YYYYMMDD@Lewis: Add dashboard type detection (RevShare/CPA/Hybrid), Date Range view support, CPA metrics, Current Month detection [RedmineID: #XXXXXX]

	Notes:
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)
	  - Data separation: rptMemberDaily for historical data (before commission boundary), DepositInfo for recent data (after commission boundary)
	  - Commission boundary = @CommissionBoundary = AFF_CommissionDate + 1 day
	  - Dashboard Type: Determined by CommGroup.GroupTypeId (1=RevShare Winloss, 2=RevShare Turnover, 3=CPA, 4=Hybrid)
	  - CPA Metrics: Use MemberCPA.StatusId (2=Eligibled, 3=Settled) and TransType (206=CPA Earning, 208=Adjustment)
	  - Date View: @IsGetMonthly=1 uses @MonthDate (Month view), @IsGetMonthly=0 uses @FromDate/@ToDate (Date Range view)
*/

BEGIN
	SET NOCOUNT ON
	
	-- Date range handling: Month view vs Date Range view
	DECLARE @BeginOfMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	
	IF @IsGetMonthly = 1
	BEGIN
		-- Month view: Use @MonthDate parameter
		IF @MonthDate IS NULL
			SET @MonthDate = GETDATE()
			
		SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
		SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @BeginOfMonth)
	END
	ELSE
	BEGIN
		-- Date Range view: Use @FromDate and @ToDate parameters
		IF @FromDate IS NULL OR @ToDate IS NULL
		BEGIN
			RAISERROR('Date Range view requires @FromDate and @ToDate parameters', 16, 1)
			RETURN
		END
		
		SET @BeginOfMonth = @FromDate
		SET @ToNextMonth = DATEADD(DAY, 1, @ToDate)  -- Inclusive end date
	END
	
	-- Detect Current Month (for conditional display logic)
	DECLARE @IsCurrentMonth BIT = 0
	IF @IsGetMonthly = 1 AND DATEPART(YEAR, @MonthDate) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, @MonthDate) = DATEPART(MONTH, GETDATE())
		SET @IsCurrentMonth = 1
	
	-- Dashboard Type Detection: RevShare (1,2), CPA (3), Hybrid (4)
	DECLARE @GroupTypeId INT, @DashboardType VARCHAR(20)
	
	SELECT TOP 1 @GroupTypeId = cg.GroupTypeId
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
	INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.GroupId = agh.GroupId
	WHERE agh.AffId = @AffId
	  AND agh.MonthDate = (
		  SELECT MAX(MonthDate) 
		  FROM dbo.AffGroupHistory WITH (NOLOCK)
		  WHERE AffId = @AffId
	  )
	
	-- Set dashboard type based on GroupTypeId
	IF @GroupTypeId IN (1, 2)
		SET @DashboardType = 'RevShare'
	ELSE IF @GroupTypeId = 3
		SET @DashboardType = 'CPA'
	ELSE IF @GroupTypeId = 4
		SET @DashboardType = 'Hybrid'
	ELSE
		SET @DashboardType = 'Unknown'

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

	-- CPA Metrics (for CPA and Hybrid dashboards)
	BEGIN
		DECLARE @CPAQuota SMALLINT = 0, @CPAEligibledCount INT = 0, @CPASettledCount INT = 0, @CPAEarning MONEY = 0
		
		IF @DashboardType IN ('CPA', 'Hybrid')
		BEGIN
			-- Get CPA Quota from CommGroup
			SELECT TOP 1 @CPAQuota = ISNULL(cg.Quota, 0)
			FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.GroupId = agh.GroupId
			WHERE agh.AffId = @AffId
			  AND agh.MonthDate = (
				  SELECT MAX(MonthDate) 
				  FROM dbo.AffGroupHistory WITH (NOLOCK)
				  WHERE AffId = @AffId
			  )
			
			-- Count Eligibled CPAs (StatusId=2) in current period
			SELECT @CPAEligibledCount = COUNT(DISTINCT mc.MemberCPA_ID)
			FROM dbo.MemberCPA mc WITH (NOLOCK)
			WHERE mc.AffId = @AffId
			  AND mc.StatusId = 2  -- Eligibled
			  AND mc.CPADate >= @BeginOfMonth
			  AND mc.CPADate < @ToNextMonth
			  AND mc.IsAbnormal = 0
			
			-- Count Settled CPAs (StatusId=3) in current period
			SELECT @CPASettledCount = COUNT(DISTINCT mc.MemberCPA_ID)
			FROM dbo.MemberCPA mc WITH (NOLOCK)
			WHERE mc.AffId = @AffId
			  AND mc.StatusId = 3  -- Settled
			  AND mc.SettleDate >= @BeginOfMonth
			  AND mc.SettleDate < @ToNextMonth
			  AND mc.IsAbnormal = 0
			
			-- Calculate CPA Earning from AffTrans (TransType 206=CPA Earning, 208=CPA Adjustment)
			SELECT @CPAEarning = SUM(ISNULL(at.Amount, 0))
			FROM dbo.AffTrans at WITH (NOLOCK)
			WHERE at.AffId = @AffId
			  AND at.TransType IN (206, 208)  -- CPA Earning and Adjustment
			  AND at.CreateDate >= @BeginOfMonth
			  AND at.CreateDate < @ToNextMonth
			  AND at.Status IN ('Pending', 'Approved', 'Completed')
		END
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
			,ISNULL(@UniqueClick, 0)		AS UniqueClick
			-- New fields for dashboard enhancement
			,@DashboardType					AS DashboardType
			,@IsCurrentMonth				AS IsCurrentMonth
			,ISNULL(@CPAQuota, 0)			AS CPAQuota
			,ISNULL(@CPAEligibledCount, 0)	AS CPAEligibledCount
			,ISNULL(@CPASettledCount, 0)	AS CPASettledCount
			,ISNULL(@CPAEarning, 0)			AS CPAEarning
	END
END
GO