/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_StatementHistory_Sel] 
	@AffId		INT,
	@FDate		SMALLDATETIME = NULL,
	@TDate		SMALLDATETIME = NULL,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Statement History

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241225@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250404@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]
		- 20251007@Danny: Show CPA info [RedmineID: #240525]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MinReportDate SMALLDATETIME
		,@EndOfTDate DATETIME
		,@CurrentDate SMALLDATETIME 

	DECLARE @AffGroupInfo TABLE (MonthDate SMALLDATETIME, AffId INT, GroupTypeName NVARCHAR(100), GroupTypeId TINYINT)

	SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(@AffId)	
	SELECT  @CurrentDate   = CONVERT(DATE, DATEADD(HOUR, 12, GETDATE()))

	IF @FDate IS NULL OR @TDate IS NULL
		SELECT @FDate = @MinReportDate, @TDate = @CurrentDate
	ELSE
	BEGIN
		SELECT @FDate = CONVERT(DATE, @FDate), @TDate = CONVERT(DATE, @TDate)
		
		IF @FDate < @MinReportDate
			SELECT @FDate = @MinReportDate
	END

	IF @FDate > @TDate
		RETURN

	SELECT @EndOfTDate = EOMONTH(@TDate) -- Last day of @TDate
	
	-- Get GroupType Info
	INSERT INTO @AffGroupInfo (MonthDate, AffId, GroupTypeName, GroupTypeId)
	SELECT af.MonthDate
		,af.AffId
		,af.GroupTypeName
		,af.GroupTypeId
	FROM dbo.Aff_f_AffGroupInfo_Sel(@FDate, @EndOfTDate, CONVERT(VARCHAR(20), @AffId)) af

	DROP TABLE IF EXISTS #tempData
	CREATE TABLE #tempData
	(
		TransId			BIGINT,
		MonthDate		SMALLDATETIME,
		TransType		INT,
		Amount			MONEY,
		Status			VARCHAR(10),
		Creator			NVARCHAR(50),
		Description		NVARCHAR(2000),
		CalculatedType	TINYINT DEFAULT ((2)) -- 0: Current Month, 1: UnCalculated Months, 2: Calculated Months
	)

	DROP TABLE IF EXISTS #tempData_CPA
	CREATE TABLE #tempData_CPA
	(
		TransId			BIGINT,
		MonthDate		SMALLDATETIME,
		TransType		INT,
		Amount			MONEY,
		Creator			NVARCHAR(50),
		Description		NVARCHAR(300)
	)

	-- CPA Payment
	BEGIN
		DECLARE @CPA_Quota INT, @Remaining INT, @Settled INT, @GroupId INT, @Tentative_amt MONEY
		DECLARE @LastMonth DATETIME = EOMONTH(@CurrentDate, -1)
		DECLARE @GroupTypeId SMALLINT

		SELECT @CPA_Quota = c.Quota , @GroupId = c.GroupId, @GroupTypeId = c.GroupTypeId
		FROM dbo.CommGroup c WITH(NOLOCK)
		INNER JOIN dbo.AffInfo a WITH(NOLOCK) ON c.GroupId = a.GroupId
		WHERE a.AffId = @AffId

		-- Tentative CPA Earning
		IF @GroupTypeId IN (3, 4) -- CPA and Hybrid
		BEGIN
			IF @TDate > @LastMonth -- Current month
			BEGIN
				IF @CPA_Quota > 0 
				BEGIN
					SELECT @Remaining = @CPA_Quota - SUM(CASE WHEN m.StatusId = 3 THEN 1 ELSE 0 END)
					FROM dbo.MemberCPA m WITH(NOLOCK)
					WHERE m.GroupId = @GroupId AND m.AffId = @AffId
					
					; WITH t AS
					(
						SELECT m.CustID, m.HoldingQualifiedDate, m.FirstDepositDate, m.CPAAmount, ROW_NUMBER() OVER(ORDER BY m.HoldingQualifiedDate ASC, mi.FirstDepositDate ASC) rn
						FROM dbo.MemberCPA m WITH(NOLOCK)
							INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON m.CustID = mi.CustID
						WHERE m.GroupId = @GroupId AND m.AffId = @AffId AND m.StatusId =  2 AND m.HoldingQualifiedDate <= @TDate
					)
					SELECT @Tentative_amt = SUM (CPAAmount) 
					FROM t 
					WHERE rn <= @Remaining

					INSERT INTO #tempData(TransId, MonthDate, TransType, Amount, Status, Creator, Description)
					SELECT	0, EOMONTH(@TDate), 209 TransType, ISNULL(@Tentative_amt, 0), 'B/F', 'System' Creator, 'Tentative CPA Earning'
				END
				ELSE --unlimited quota
				BEGIN
					INSERT INTO #tempData(TransId, MonthDate, TransType, Amount, Status, Creator, Description)
					SELECT	0, EOMONTH(@TDate), 209 TransType, ISNULL(SUM(m.CPAAmount), 0), 'B/F', 'System' Creator, 'Tentative CPA Earning'
					FROM dbo.MemberCPA m WITH(NOLOCK)
					WHERE m.GroupId = @GroupId AND m.AffId = @AffId AND m.StatusId =  2 AND m.HoldingQualifiedDate <= @TDate
				END
			END
		END

		INSERT INTO #tempData_CPA (TransId, MonthDate, TransType, Amount, Creator, Description)
		SELECT  at.TransId, at.WinlostDate,  at.TransType, at.Amount, ISNULL(au.Username, 'System') AS Creator, at.Description
		FROM dbo.AffTrans at WITH(NOLOCK)
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON at.Creator = au.custid
		WHERE AffID = @AffId 
			AND at.TransType IN (206, 208, 204)
			AND at.WinlostDate BETWEEN @FDate AND @TDate

	 -- Approved CPA Earning, Sub Commission If Any
		INSERT INTO #tempData(TransId, MonthDate, TransType, Amount, Status, Creator, Description)
		SELECT 0, EOMONTH(MonthDate), TransType, SUM(Amount), 'B/F', 'System' Creator, 'Approved CPA Earning'
		FROM #tempData_CPA
		WHERE TransType IN (206)
		GROUP BY EOMONTH(MonthDate), TransType

	 -- Approved CPA Earning, Sub Commission If Any
		INSERT INTO #tempData(TransId, MonthDate, TransType, Amount, Status, Creator, Description)
		SELECT 0, t.MonthDate, TransType, SUM(Amount), 'B/F', 'System' Creator, 'Sub-Affiliate Revenue Share'
		FROM #tempData_CPA t
		WHERE TransType IN (204)
			AND EXISTS (SELECT TOP 1 1 FROM @AffGroupInfo a WHERE a.MonthDate = t.MonthDate AND a.GroupTypeId IN (3,4))
		GROUP BY t.MonthDate, TransType

	--  CPA Adjustment
		INSERT INTO #tempData(TransId, MonthDate, TransType, Amount, Status, Creator, Description)
		SELECT TransId, MonthDate, TransType, Amount, 'B/F', Creator, Description
		FROM #tempData_CPA
		WHERE TransType = 208

	END

	-- Payment, Adjustment info (TransType = 202, 203)
	BEGIN
		INSERT INTO #tempData
		(
			TransId,
			MonthDate,
			TransType,
			Amount,
			Status,
			Creator,
			Description
		)
		SELECT
			at.TransId,
			DATEADD(HOUR, 12, at.TransDate) AS TransDate, -- Changed from GMT-4 to GMT+12
			at.TransType,
			CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END AS Amount,
			CASE WHEN at.TransType = 202 THEN at.Status ELSE 'B/F' END AS Status,
			ISNULL(au.Username, 'System') AS Creator,
			CASE WHEN at.TransType = 202 THEN ap.AdminDesc ELSE at.Description END AS Description
		FROM dbo.AffTrans at WITH (NOLOCK)
			LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID AND at.TransType = 202
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON at.Creator = au.custid
		WHERE at.AffId = @AffId
			AND at.TransType IN (202, 203)
			AND at.WinlostDate >= @FDate AND at.WinlostDate < DATEADD(DAY, 1, @TDate)
	END

	-- Commission info
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		-- Calculated months
		IF @FDate <= @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= @FDate
			SELECT @tempToDate		= CASE WHEN @TDate > @MaxCommDate THEN @MaxCommDate ELSE @TDate END
			
			-- get Comm, SubComm for rev and Hybrid
			INSERT INTO #tempData
			(
				TransId,
				MonthDate,
				TransType,
				Amount,
				Status,
				Creator,
				Description
			)
			SELECT
				0,
				MonthDate,
				TransType,
				SUM(Amount),
				'B/F' AS Status,
				'System' AS Creator,
				CASE WHEN TransType = 201 THEN 'Monthly Earning (Revenue Share)' ELSE 'Sub-Affiliate Revenue Share' END AS Description
			FROM (
				SELECT md.MonthDate, at.TransType, ISNULL(at.Amount, 0) AS Amount
				FROM @AffGroupInfo md
					OUTER APPLY (
						SELECT at.TransType, at.Amount
						FROM dbo.AffTrans at WITH (NOLOCK)
						WHERE md.MonthDate = at.WinlostDate
							AND at.AffId = @AffId
							AND at.TransType IN (201, 204)
					) at
				WHERE md.GroupTypeId <> 3
					AND md.MonthDate <= @MaxCommDate
			) t
			GROUP BY MonthDate, TransType

		END

		-- Uncalculated months
		DECLARE @AffIds VARCHAR(20)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		IF @TDate > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= CASE WHEN @FDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FDate END,
					@tempToDate		= @TDate

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
				QualifiedMember		INT DEFAULT (0),
				CommissionRate		FLOAT,
				Commission			MONEY,
				StraightCommission	MONEY,
				SubAffCommission	MONEY,
				IsMultiGroupProduct BIT
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
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= @AffIds,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@ProductIds			= '0',
				@IsSumAll			= 0,
				@GetRowTotalOnly	= 1
		
			;WITH CTE_MonthDate AS
			(
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @tempFromDate) + 1, 0)) AS MonthDate
				UNION ALL
				SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
				FROM CTE_MonthDate
				WHERE MonthDate < @tempToDate
			)
			INSERT INTO #tempData
			(
				TransId,
				MonthDate,
				TransType,
				Amount,
				Status,
				Creator,
				Description,
				CalculatedType
			)
			SELECT
				0,
				MonthDate,
				TransType,
				SUM(Amount),
				'B/F' AS Status,
				'System' AS Creator,
				CASE WHEN MonthDate >= @CurrentDate THEN 'Current ' ELSE 'UnCalculated ' END
					+ CASE WHEN TransType = 201 THEN 'Tentative Monthly Earning (Revenue Share)' ELSE 'Tentative Sub-Affiliate Revenue Share' END AS Description,
				CASE WHEN MonthDate >= @CurrentDate THEN 0 ELSE 1 END AS CalculatedType
			FROM (
				SELECT md.MonthDate,TransType, ISNULL(at.Amount, 0) AS Amount
				FROM CTE_MonthDate md
					OUTER APPLY (
						SELECT c.Commission, c.SubAffCommission
						FROM #TempCommission c
						WHERE md.MonthDate = c.MonthDate
							AND c.AffId = @AffId
							AND c.ProductId = 0
					) c
					OUTER APPLY (
						SELECT 201 AS TransType, c.Commission AS Amount
						WHERE @GroupTypeId <> 3 -- Not CPA only for 201 in current month
						UNION ALL 
						SELECT 204, c.SubAffCommission
					) at
			) t
			GROUP BY MonthDate, TransType
			OPTION (MAXRECURSION 0)

			DROP TABLE #TempCommission
		END
	END

	-- Return data
	SELECT @NRows = COUNT(1) FROM #tempData WHERE TransType <> 204

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT
		TransId,
		result.MonthDate,
		TransType,
		Amount,
		Status,
		Creator,
		--CASE WHEN result.TransType = 201 AND ISNULL(ag.GroupTypeName, '') <> '' THEN CONCAT(RESULT.Description,' (',ag.GroupTypeName,')')ELSE  Description END AS Description,
		Description,
		CalculatedType
	FROM
	(
		SELECT
			TransId,
			MonthDate,
			TransType,
			Amount,
			Status,
			Creator,
			Description,
			CalculatedType,
			DENSE_RANK() OVER(ORDER BY MonthDate DESC, CASE WHEN TransType IN (201, 204, 206, 208, 209) THEN 0 ELSE TransId END DESC) AS RowNum
		FROM #tempData
	) AS result
		LEFT JOIN @AffGroupInfo ag ON ag.MonthDate = result.MonthDate
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

END
GO