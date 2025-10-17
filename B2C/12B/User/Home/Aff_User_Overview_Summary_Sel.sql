/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE  PROCEDURE [dbo].[Aff_User_Overview_Summary_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@IsGetMonthly  BIT = 1
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
		- 20250918@Lewis: Get CPAAmount data [RedmineID: #238519]

	Notes:
	  - rptMemberDaily.WinlostDate is in GMT+8
	  - bodb_12B.dbo.DepositInfo.CreateTime is in GMT+0
	  - bodb_12B.dbo.DepositInfo.WinlostDate is indexed (Date of CreateTime)
	  - Data separation: rptMemberDaily for historical data (before commission boundary), DepositInfo for recent data (after commission boundary)
	  - Commission boundary = @CommissionBoundary = AFF_CommissionDate + 1 day
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @FDate SMALLDATETIME
			,@TDate SMALLDATETIME

	-- Calculate commission date boundary for data separation (commission date + 1 day)
	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency
	
	-- AffCurrency
	DECLARE @AffCurrency INT
	SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')

	-- Get affcurrency mapping
	DECLARE @AffExchangeId INT = @AffCurrency
	SELECT  @AffExchangeId = tp.ExchangeId
	FROM dbo.TpExchange tp WITH (NOLOCK)
	WHERE tp.TpExchangeId = @AffCurrency

	-- Click Statistics
	BEGIN
		DECLARE @TotalClick INT, @UniqueClick INT;
		
		DECLARE @ArchiveDate SMALLDATETIME;
		SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics'); -- GMT-4, Date only, end of last month
	
		-- Convert from GMT+8 to GMT-4 for comparison with ClickStatistics.Date
		DECLARE @FromDate_GMT4 DATETIME, @ToDate_GMT4 DATETIME;
		SELECT @FromDate_GMT4 = DATEADD(HOUR, -12, CAST(@FromDate AS DATETIME)), -- GMT+8 to GMT-4
			   @ToDate_GMT4 = DATEADD(HOUR, -12, CAST(DATEADD(DAY, 1, @ToDate) AS DATETIME)); -- GMT+8 to GMT-4
	
		CREATE TABLE #ClickData (TotalClick INT DEFAULT(0), IP VARCHAR(25));
		
		-- Current data
		IF CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate
		BEGIN
			SELECT @FromDate_GMT4 = IIF(CONVERT(DATE, @FromDate_GMT4) > @ArchiveDate, @FromDate_GMT4, DATEADD(DAY, 1, @ArchiveDate))
					,@ToDate_GMT4 = @ToDate_GMT4

			INSERT INTO #ClickData (TotalClick, IP)
			SELECT COUNT(1) AS TotalClick, IP
			FROM dbo.ClickStatistics WITH (NOLOCK)
			WHERE AffId = @AffID
				AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4
				AND [Date] >= CONVERT(DATE, @FromDate_GMT4)
				AND [Date] <= CONVERT(DATE, @ToDate_GMT4)
				AND IsExcluded = 0
			GROUP BY IP;
		END;

		-- Archived data
		IF CONVERT(DATE, @FromDate_GMT4) <= @ArchiveDate
		BEGIN
			SELECT @FromDate_GMT4 = @FromDate_GMT4
					,@ToDate_GMT4 = IIF(CONVERT(DATE, @ToDate_GMT4) >= @ArchiveDate, DATEADD(DAY, 1, @ArchiveDate), @ToDate_GMT4)

			INSERT INTO #ClickData (TotalClick, IP)
			SELECT COUNT(1) AS TotalClick, IP
			FROM dbo.ClickStatistics_bk WITH (NOLOCK)
			WHERE AffId = @AffID
				AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4
				AND [Date] >= CONVERT(DATE, @FromDate_GMT4)
				AND [Date] <= CONVERT(DATE, @ToDate_GMT4)
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
		
		SELECT  @Signups		   = COUNT(CASE WHEN RegisteredDate >= @FromDate AND RegisteredDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE NULL END)
				,@DepositedMembers = COUNT(CASE WHEN FirstDepositDate >= @FromDate AND FirstDepositDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE NULL END)			
		FROM dbo.MemberInfo m WITH (NOLOCK)
		WHERE AffId = @AffId

		SELECT @FDMDeposit = SUM(fd.FirstDepositAmount * ex.Rate)
		FROM (
			SELECT Currency
				,SUM(ISNULL(FirstDepositAmount,0)) AS FirstDepositAmount
				,CONVERT(DATE, EOMONTH(FirstDepositDate)) AS MonthDate
			FROM dbo.MemberInfo r WITH (NOLOCK)
			WHERE AffId = @AffId
				AND FirstDepositDate >= @FromDate 
				AND FirstDepositDate < DATEADD(DAY, 1, @ToDate)
			GROUP BY Currency, CONVERT(DATE, EOMONTH(FirstDepositDate))
		) fd
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON fd.Currency = t.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(fd.MonthDate, ISNULL(t.ExchangeId, fd.Currency), @BaseExchangeId) ex
	END

	-- Total Deposit - Conditional hybrid approach
	BEGIN
		DECLARE @Deposit MONEY

		-- Range current month
		IF @ToDate > @MaxCommDate
		BEGIN
			--GMT0
			SELECT @FDate = IIF(@FromDate <= @MaxCommDate, DATEADD(DAY, 1, @MaxCommDate), @FromDate) --GMT+8
					, @TDate = DATEADD(DAY, 1, @ToDate) --GMT+8

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
					AND d.WinlostDate >= @FDate 
					AND d.WinlostDate < @TDate  -- Use WinlostDate index with pre-calculated DATE variables
					AND d.CreateTime >= DATEADD(HOUR, -8, @FDate)  -- GMT0
					AND d.CreateTime < DATEADD(HOUR, -8, @TDate)  -- GMT0
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

		-- Range Last Month
		IF @FromDate <= @MaxCommDate
		BEGIN
			--GMT8
			SELECT @FDate = @FromDate
					, @TDate = IIF(@ToDate > @MaxCommDate, @MaxCommDate, @ToDate)

			-- Use rptMemberDaily only for historical data with currency grouping optimization
			SELECT @Deposit = SUM(rd.Deposit * ex.Rate)
			FROM (
				SELECT Currency
					,SUM(ISNULL(Deposit, 0)) AS Deposit
					,CONVERT(DATE, EOMONTH(WinlostDate)) AS MonthDate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate >= @FDate 
					AND r.WinlostDate <= @TDate
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
	END

	-- Balance Brought Forward
	BEGIN
		DECLARE @BBF MONEY
		SELECT  @BBF = SUM(Amount)
		FROM dbo.AffTrans WITH (NOLOCK)
		WHERE AffId = @AffId
			AND WinlostDate <= @ToDate
			AND Status IN ('Pending', 'Approved', 'Completed')
	END

	-- Active Players, Turnover, Deposit, Commission, QualifiedMember, NetGGR
	BEGIN
		DECLARE @NoOfSubAff INT, @ActivePlayers INT, @QualifiedMember INT, @Turnover MONEY, @Commission MONEY, @SubAffCommission MONEY, @NetGGR MONEY

		SELECT @NoOfSubAff = COUNT(1)
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ParentAffId = @AffId
			AND Status = 'Approved'
			AND IsRejected = 0
			AND ApprovedDate >= @FromDate AND ApprovedDate < DATEADD(DAY, 1, @ToDate)

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

		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		IF @ToDate > @MaxCommDate  AND @IsGetMonthly = 1
		BEGIN
			SELECT @FDate	= IIF(@FromDate <= @MaxCommDate, DATEADD(DAY, 1, @MaxCommDate), @FromDate)
			SELECT @TDate	= @ToDate

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
				@FromMonthDate		= @FDate,
				@ToMonthDate		= @TDate,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		IF @FromDate <= @MaxCommDate AND @IsGetMonthly = 1
		BEGIN
			
			SELECT @FDate	= @FromDate
			SELECT @TDate	= IIF(@ToDate > @MaxCommDate, @MaxCommDate, @ToDate)

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
				@FromMonthDate		= @FDate,
				@ToMonthDate		= @TDate,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		IF(@IsGetMonthly = 0)
		-- only show Active Players, QualifiedMember
		BEGIN
			
			SELECT @FDate	= @FromDate
			SELECT @TDate	= @ToDate

			CREATE TABLE #DataMemberDaily (MonthDate SMALLDATETIME, AffId INT, Currency INT, CustId INT, ProductId INT, Bonus MONEY, Rebate MONEY, Turnover MONEY, Winloss MONEY)
			CREATE CLUSTERED INDEX IX_DataMemberDaily ON #DataMemberDaily (MonthDate, AffId)
			INSERT INTO #DataMemberDaily
			(
				MonthDate,
				AffId,
				Currency,
				CustId,
				ProductId,
				Bonus,
				Rebate,
				Turnover,
				Winloss
			)
			SELECT CONVERT(SMALLDATETIME,EOMONTH(r.WinlostDate)) AS MonthDate
					,r.AffId
					,Currency
					,CustId
					,r.ProductId
					,SUM(ISNULL(Bonus, 0))		AS Bonus
					,SUM(ISNULL(Rebate, 0))		AS Rebate
					,SUM(ISNULL(Turnover, 0))	AS Turnover
					,SUM(ISNULL(Winloss, 0) - ISNULL(ProgressiveWin, 0) + ISNULL(ProgressiveBet, 0)) AS Winloss				
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			WHERE r.WinlostDate >= @FDate 
				AND r.WinlostDate <= @ToDate
				AND r.AffId = @AffId
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) 
					WHERE mr.CustId = r.custid AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
				)
			GROUP BY CONVERT(SMALLDATETIME,EOMONTH(r.WinlostDate))
				,r.AffId
				,Currency
				,CustId
				,r.ProductId

			DECLARE @AffInfo TABLE (AffId INT, AffUsername VARCHAR(50),MonthDate SMALLDATETIME, GroupId INT, QMTurnover MONEY)
			INSERT INTO @AffInfo (AffId, AffUsername, MonthDate, GroupId)
				SELECT a.AffId, a.Username, agh.MonthDate, a.GroupId
				FROM (
					SELECT DISTINCT AffId, MonthDate FROM #DataMemberDaily
				)t
					INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON t.AffId = a.AffId
					INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON a.AffId = agh.AffId AND agh.MonthDate = t.MonthDate
				WHERE a.AffId = @AffId
					AND Status NOT IN ('Pending', 'Disapproved')					
			
			UPDATE a SET a.QMTurnover = ISNULL(cg.QMTurnover, 0) * e.Rate
			FROM @AffInfo a
				INNER JOIN dbo.CommGroupHistory cg WITH (NOLOCK) ON a.GroupId = cg.GroupId AND a.MonthDate = cg.MonthDate
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(a.MonthDate, @AffExchangeId, @BaseExchangeId) e
			
			;WITH CTE_DataResult AS(
				SELECT  r.AffId
					,SUM(r.Bonus		* e.Rate)	AS Bonus
					,SUM(r.Rebate		* e.Rate)	AS Rebate
					,SUM(r.Turnover		* e.Rate)	AS Turnover
					,SUM(r.Winloss		* e.Rate)	AS Winloss
					,- SUM(r.Winloss	* e.Rate)	AS GrossWinloss
				FROM #DataMemberDaily r
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.MonthDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
				GROUP BY r.AffId
			)
			, CTE_QualifieldMember AS (
				SELECT r.AffId, r.MonthDate, COUNT(DISTINCT IIF(r.Turnover >= a.QMTurnover, r.CustId, NULL)) AS QualifiedMember
				FROM (
					SELECT c.AffId, c.MonthDate, c.CustId, SUM(ISNULL(c.Turnover, 0) * e.Rate) AS Turnover
					FROM #DataMemberDaily c
						LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON c.Currency = t.TpExchangeId
						CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(c.MonthDate, ISNULL(t.ExchangeId, c.Currency), @BaseExchangeId) e
					GROUP BY c.AffId, c.MonthDate, c.CustId
				)r
					INNER JOIN @AffInfo a ON a.AffId = r.AffId AND r.MonthDate = a.MonthDate
				GROUP BY r.AffId, r.MonthDate
			)
			, CTE_ActivePlayer AS (
				SELECT r.AffId, r.MonthDate, COUNT(DISTINCT IIF(r.productId > 0, r.CustId, NULL)) AS ActivePlayer
				FROM #DataMemberDaily r
				GROUP BY r.AffId, r.MonthDate
			)
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
			SELECT @FromDate
					,t.AffId
					,0 AS GroupId
					,0 AS ProductId
					,0 AS Deposit
					,0 AS Withdrawal
					,t.Bonus
					,t.Rebate
					,t.Turnover
					,t.Winloss
					,0 AS Revenue
					,0 AS P2PFee
					,0 AS PlatFormFee
					,0 AS OperationalFee
					,0 AS DepositFee
					,0 AS WithdrawalFee
					,t.GrossWinloss
					,0 AS NetWinloss
					,0 AS NetTurnover
					,ISNULL(ap.ActivePlayer, 0) AS ActivePlayer
					,ISNULL(qm.QualifiedMember, 0) AS QualifiedMember
					,0 AS CommissionRate
					,0 AS Commission
					,0 AS StraightCommission
					,0 AS SubAffCommission
					,0 AS IsMultiGroupProduct 
			FROM CTE_DataResult t		
				OUTER APPLY(
					SELECT SUM(QualifiedMember) AS QualifiedMember 
					FROM CTE_QualifieldMember q
					WHERE q.AffId = t.AffId
				)qm 
				OUTER APPLY(
					SELECT SUM(ActivePlayer) AS ActivePlayer 
					FROM CTE_ActivePlayer q
					WHERE q.AffId = t.AffId
				)ap
			DROP TABLE #ProductSetting
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

	-- ===============================
	-- CPA INFO
	-- ===============================
	DECLARE @ApprovedCPAAmount MONEY --Approved
			,@TentativeCPAAmount MONEY
			,@IsHybridSetting BIT = 0
			,@GroupTypeName NVARCHAR(200)
			,@QualifiedMemberCPA INT
			,@RemainQuota INT
			,@Quota INT
			,@GroupId INT
	
	-- GroupTypeId, GroupId, Quota
	SELECT @GroupTypeName = gt.GroupTypeName
		  ,@GroupId = agh.GroupId
		  ,@Quota = IIF(cg.Quota = 0, NULL, cg.Quota) -- Quota = 0 ==> unlimited quota
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.IsDeleted = 0 AND cg.GroupId = agh.GroupId
		INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON cg.GroupTypeId = gt.GroupTypeId
	WHERE agh.MonthDate BETWEEN @FromDate AND @ToDate
		AND agh.AffId = @AffId
		AND agh.MonthDate = EOMONTH(agh.MonthDate) -- 1groupid 1affid 1month

	-- IsHybridSetting
	IF EXISTS ( --Hybrid
				SELECT TOP 1 1
				FROM dbo.AffGroupHistory agh WITH (NOLOCK)
				JOIN dbo.CommGroup cg WITH (NOLOCK) 
					ON cg.GroupId = agh.GroupId
				WHERE agh.AffId = @AffId
				  AND agh.MonthDate BETWEEN @FromDate AND @ToDate
				  AND cg.IsDeleted = 0
				  AND cg.GroupTypeId = 4 
		)
		OR ( --Revenue and CPA
			EXISTS (
					SELECT TOP 1 1
					FROM dbo.AffGroupHistory agh WITH (NOLOCK)
					JOIN dbo.CommGroup cg WITH (NOLOCK) 
						ON cg.GroupId = agh.GroupId
					WHERE agh.AffId = @AffId
					  AND agh.MonthDate BETWEEN @FromDate AND @ToDate
					  AND cg.IsDeleted = 0
					  AND cg.GroupTypeId = 1
			)
			AND EXISTS (
						SELECT TOP 1 1
						FROM dbo.AffGroupHistory agh WITH (NOLOCK)
						JOIN dbo.CommGroup cg WITH (NOLOCK)
							ON cg.GroupId = agh.GroupId
						WHERE agh.AffId = @AffId
						  AND agh.MonthDate BETWEEN @FromDate AND @ToDate
						  AND cg.IsDeleted = 0
						  AND cg.GroupTypeId = 3
			)
		)
	BEGIN
		SET @IsHybridSetting = 1
	END

	-- ApprovedCPAAmount
	SELECT @ApprovedCPAAmount = SUM(m.CPAAmount)
		  ,@QualifiedMemberCPA = COUNT(m.CustId)
	FROM dbo.MemberCPA m WITH (NOLOCK)
	WHERE m.AffId = @AffId
		AND m.CPADate BETWEEN @FromDate AND @ToDate --View by CPADate
		AND m.StatusId = 3 -- Settled
	
	-- RemainQuota
	SELECT @RemainQuota = @Quota - COUNT(m.CustId) -- => Remain = NULL ==> unlimited quota
	FROM dbo.MemberCPA m WITH (NOLOCK)
	WHERE m.AffId = @AffId
		AND m.StatusId = 3 -- Settled
	
	-- QualifiedMemberCPA
	SELECT @QualifiedMemberCPA += IIF(@RemainQuota IS NULL, COUNT(m.CustId), IIF(COUNT(m.CustId) <= @RemainQuota, COUNT(m.CustId), @RemainQuota))
	FROM dbo.MemberCPA m WITH (NOLOCK)
	WHERE m.AffId = @AffId
		AND m.StatusId = 2
		AND m.HoldingQualifiedDate BETWEEN @FromDate AND @ToDate --View by HoldingQualifiedDate

	-- TentativeCPAAmount -- up to now - and check quota slot
	;WITH cte_TentativeMember AS (
		SELECT m.CustId
			  ,m.CPAAmount
			  ,ROW_NUMBER() OVER (
                       ORDER BY m.HoldingQualifiedDate ASC,
                                mi.FirstDepositDate ASC
                   ) AS RowNum
		FROM dbo.MemberCPA m WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON m.CustId = mi.CustId
		WHERE m.AffId = @AffId
			AND m.HoldingQualifiedDate <= @ToDate --View by HoldingQualifiedDate
			AND m.StatusId = 2 -- Estimated
	)
	, cte_TentativeCPAAmount AS (
		SELECT CustId
			  ,CPAAmount
			  ,RowNum
		FROM cte_TentativeMember
		WHERE RowNum <= IIF(@RemainQuota IS NOT NULL, @RemainQuota, RowNum)
	)
	SELECT @TentativeCPAAmount = SUM(CPAAmount)
	FROM cte_TentativeCPAAmount

	-- Return result
	BEGIN
		SELECT
			ISNULL(@Signups, 0)				AS Signups
			,ISNULL(@DepositedMembers, 0)	AS DepositedMembers
			,ISNULL(@BBF, 0)				AS BalanceBroughtForward
			,ISNULL(@ActivePlayers, 0)		AS ActivePlayers
			,ISNULL(@QualifiedMember, 0)	AS QualifiedMember --revenue
			,ISNULL(@Turnover, 0)			AS Turnover
			,ISNULL(@Deposit, 0)			AS Deposit
			,ISNULL(@Commission, 0)			AS Commission
			,ISNULL(@NoOfSubAff, 0)			AS NoOfSubAff
			,ISNULL(@SubAffCommission, 0)	AS SubAffCommission
			,ISNULL(@FDMDeposit, 0)			AS FDMDeposit
			,ISNULL(@NetGGR, 0)				AS NetGGR
			,ISNULL(@TotalClick, 0)			AS TotalClick
			,ISNULL(@UniqueClick, 0)		AS UniqueClick
			--CPA
			,ISNULL(@ApprovedCPAAmount, 0)	AS ApprovedCPAAmount
			,ISNULL(@TentativeCPAAmount, 0)	AS TentativeCPAAmount
			,ISNULL(@QualifiedMemberCPA,0)	AS QualifiedMemberCPA --CPA
			,@IsHybridSetting				AS IsHybridSetting
			,@GroupTypeName					AS GroupType
	END
END
GO