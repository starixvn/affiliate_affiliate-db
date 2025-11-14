/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Overview_SubAffiliate_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@IsGetMonthly  BIT = 1
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Sub-Affiliate Details

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241226@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250918@Lewis: Get Qualified CPA Member [RedmineID: #238519]

*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @FDate SMALLDATETIME
			,@TDate SMALLDATETIME

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

	-- Total Turnover, Winloss, Commission
	BEGIN
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
		
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120)
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName = 'AFF_CommissionDate'
		
		--get sub affids
		SELECT  @AffIds = COALESCE(@AffIds + ',', '') + CONVERT(VARCHAR(20), AffId)
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ParentAffId = @AffId
			AND Status = 'Approved'
			AND IsClosed = 0
			AND ISNULL(IsSuspended, 0) = 0
			AND ApprovedDate < DATEADD(DAY, 1, @ToDate)

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
	END
	
	IF(@IsGetMonthly = 0)
	-- Show TurnOver, GGR, ActivePlayers, QualifiedRevPlayer
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
				AND EXISTS (SELECT TOP 1 1 FROM string_split(@AffIds,',') s WHERE CAST(s.value AS INT) = r.AffId)
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
				WHERE EXISTS (SELECT TOP 1 1 FROM string_split(@AffIds,',') s WHERE CAST(s.value AS INT) = a.AffId)
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
			DROP TABLE #DataMemberDaily 
	END
	
	-- QualifiedMemberCPA
	DECLARE @TimeZone SMALLINT
	SELECT  @TimeZone = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'
	DECLARE @CurrentDate DATE = DATEADD(HOUR, @TimeZone, GETUTCDATE())
	DECLARE @QualifiedMemberCPA TABLE (AffId INT, QualifiedMemberCPA INT)

	;WITH CTE_Settled AS (
			SELECT AffId
				, COUNT(CustId) AS SettledPlayer
			FROM dbo.MemberCPA mc WITH (NOLOCK)
			WHERE mc.CPADate BETWEEN @FromDate AND @ToDate
				AND mc.StatusId = 3
				AND EXISTS (SELECT TOP 1 1 FROM string_split(@AffIds,',') s WHERE CAST(s.value AS INT) = mc.AffId)
			GROUP BY AffId
		)
		,CTE_Eligible AS (
			SELECT mc.AffId
				, COUNT(mc.CustId) AS EligibledPlayer
			FROM dbo.MemberCPA mc WITH (NOLOCK)
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON mc.AffId = agh.AffId AND mc.GroupId = agh.GroupId AND agh.ToDate = '9999-12-31'
			WHERE mc.HoldingQualifiedDate <= @ToDate
				AND MONTH(@ToDate) = MONTH(@CurrentDate) --current month
				AND mc.StatusId = 2
				AND EXISTS (SELECT TOP 1 1 FROM string_split(@AffIds,',') s WHERE CAST(s.value AS INT) = mc.AffId)
			GROUP BY mc.AffId
		)
		,CTE_Remaining AS (
			SELECT mc.AffId
				, IIF(cpg.Quota = 0, NULL, cpg.Quota - COUNT(mc.CustId)) AS Remaining -- NULL is unlimitedQuota
			FROM dbo.MemberCPA mc WITH (NOLOCK)
				INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON mc.AffId = agh.AffId AND mc.GroupId = agh.GroupId AND agh.ToDate = '9999-12-31' -- get current groupid of AFF to get quota
				INNER JOIN dbo.CPAGroupSetting cpg WITH (NOLOCK) ON mc.GroupId = cpg.GroupId AND cpg.ToDate = '9999-12-31'
			WHERE mc.StatusId = 3
				AND EXISTS (SELECT TOP 1 1 FROM string_split(@AffIds,',') s WHERE CAST(s.value AS INT) = mc.AffId)
			GROUP BY mc.AffId, cpg.Quota
		)
		,CTE_AffIds AS(
			SELECT AffId FROM CTE_Settled
			UNION
			SELECT AffId FROM CTE_Eligible
			UNION
			SELECT AffId FROM CTE_Remaining
		),
		CTE_QualifiedPlayerCPA AS(
			SELECT COALESCE(s.AffId, e.AffId, r.AffId) AS AffId
				,ISNULL(s.SettledPlayer, 0) + IIF(r.Remaining IS NULL, ISNULL(e.EligibledPlayer, 0), IIF(ISNULL(e.EligibledPlayer, 0) <= r.Remaining, ISNULL(e.EligibledPlayer, 0), r.Remaining)) AS QualifiedMemberCPA
			FROM CTE_Settled s
				FULL OUTER JOIN CTE_Eligible e ON s.AffId = e.AffId
				FULL OUTER JOIN CTE_Remaining r ON ISNULL(s.AffId, e.AffId) = r.AffId
		)	
		-- @QualifiedMemberCPA
		INSERT INTO @QualifiedMemberCPA (AffId, QualifiedMemberCPA)
		SELECT t.AffId, SUM(t.QualifiedMemberCPA)
		FROM CTE_QualifiedPlayerCPA t
		GROUP BY t.AffId

	--GroupTypeName
	DECLARE @GroupTypeName TABLE (AffId INT, GroupTypeName VARCHAR(200))
	
	-- @GroupTypeName
	INSERT INTO @GroupTypeName (AffId, GroupTypeName)
	SELECT 
		AffId,
		CASE 
			WHEN MAX(CASE WHEN GroupTypeId = 4 THEN 1 ELSE 0 END) = 1 THEN 'Hybrid CPA/Revenue Share'
			WHEN MAX(CASE WHEN GroupTypeId = 1 THEN 1 ELSE 0 END) = 1
				 AND MAX(CASE WHEN GroupTypeId = 3 THEN 1 ELSE 0 END) = 1 THEN 'Hybrid CPA/Revenue Share'
			WHEN MAX(CASE WHEN GroupTypeId = 3 THEN 1 ELSE 0 END) = 1 THEN 'CPA'
			WHEN MAX(CASE WHEN GroupTypeId = 1 THEN 1 ELSE 0 END) = 1 THEN 'Revenue Share'
		END AS GroupTypeName
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.IsDeleted = 0 AND agh.GroupId = cg.GroupId
	WHERE EXISTS (
			SELECT TOP 1 1 
			FROM string_split(@AffIds, ',') s 
			WHERE CAST(s.value AS INT) = agh.AffId
		)
		AND agh.FromDate <= @ToDate
		AND agh.ToDate >= @FromDate
	GROUP BY AffId;

	
	-- Return data
	BEGIN

		SELECT
			ai.AffId
			,ai.UserName
			,ai.FirstName
			,ai.LastName
			,ai.ApprovedDate
			,ai.IsSuspended
			,ai.SuspendedDate
			,c.Turnover
			,c.GGR
			,c.Commission
			,c.ActivePlayer
			,c.QualifiedMember
			,qmc.QualifiedMemberCPA AS QualifiedMemberCPA
			,gt.GroupTypeName AS GroupTypeName
		FROM dbo.AffInfo ai WITH (NOLOCK)
			OUTER APPLY (
				SELECT
					SUM(c.Turnover) AS Turnover
					,SUM(-c.Winloss + c.Revenue) AS GGR
					,SUM(c.Commission + c.StraightCommission + c.SubAffCommission) AS Commission
					,SUM(c.ActivePlayer) AS ActivePlayer
					,SUM(c.QualifiedMember) AS QualifiedMember
				FROM #TempCommission c
				WHERE ai.AffId = c.AffId
					AND ISNULL(ai.IsSuspended, 0) = 0
			) c
			OUTER APPLY (
				SELECT
					SUM(qmc.QualifiedMemberCPA) AS QualifiedMemberCPA
				FROM @QualifiedMemberCPA qmc
				WHERE ai.AffId = qmc.AffId
					AND ISNULL(ai.IsSuspended, 0) = 0
			) qmc
			LEFT JOIN @GroupTypeName gt ON gt.AffId = ai.AffId
		WHERE ai.ParentAffId = @AffId
			AND ai.Status = 'Approved'
			AND ai.IsClosed = 0
			AND ai.ApprovedDate < DATEADD(DAY, 1, @ToDate)
		ORDER BY
			ai.IsSuspended ASC
			,ai.UserName ASC
	END

	DROP TABLE #TempCommission
END
GO