/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_API_AffiliateInfo_Sel]
	@MonthDate DATE
	,@Player_Username VARCHAR(30) = ''
	,@BaseCurrencyName VARCHAR(3) = 'USD'
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(MAX)	= '' OUTPUT

AS

/*
	Created: 20220907@Malcolm
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Get affiliate information

	Revisions:
		- 20220907@Malcolm: Initialize SP [RedmineID: #177552]
		- 20240506@Sally: Calculate Revenue Share By Turnover [RedmineID: #203756]
		- 20250515@Sally: Apply the commission calculation method used for OT to NV [RedmineID: #226985]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT = NULL

	SELECT @AffId = AffId FROM AffDetail WITH(NOLOCK) WHERE Player_Username = @Player_Username
		
	DECLARE @FromDate DATE, @ToDate DATE
	SELECT  @ToDate	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)) -- End Of previous Month
	SELECT  @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate), 0) -- begin Of previous Month

	DECLARE @BaseCurrency INT
	DECLARE @CurrencyTmp TABLE (CurrencyId INT, CurrencyName VARCHAR(5))

	DECLARE @BaseCurrencies XML
	SELECT  @BaseCurrencies = REPLACE(N'<root><r ID="' + REPLACE(SValue, ',', '" /><r ID="') + '" /></root>', ':', '" Name="')
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_BaseCurrencies'

	INSERT INTO @CurrencyTmp (CurrencyId, CurrencyName)
	SELECT
		t.c.value('@ID', 'INT'),
		t.c.value('@Name', 'VARCHAR(5)')
	FROM @BaseCurrencies.nodes('/root/r') AS t(c)

	SELECT @BaseCurrency = CurrencyId FROM @CurrencyTmp WHERE CurrencyName = @BaseCurrencyName

	IF @MonthDate IS NULL OR @AffId IS NULL OR @BaseCurrency IS NULL
	BEGIN	
		SELECT @ErrCode = 100, @ErrMsg = CASE WHEN @MonthDate IS NULL THEN 'MonthDate is invalid.'
											  WHEN @AffId	  IS NULL THEN 'Player_Username is invalid.'
										 ELSE 'BaseCurrencyName is invalid.' END

		RETURN
	END

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

	/*
		===== Get data =====
	*/
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
			QualifiedMember		INT,
			CommissionRate		FLOAT,
			Commission			MONEY,
			StraightCommission	MONEY,
			SubAffCommission	MONEY,
			IsMultiGroupProduct BIT
		)

		IF @FromDate <= @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= @FromDate
			SELECT @tempToDate		= CASE WHEN @ToDate > @MaxCommDate THEN @MaxCommDate ELSE @ToDate END

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
				@AffIds				= @AffId,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

		IF @ToDate > @MaxCommDate
		BEGIN
			SELECT @tempFromDate	= CASE WHEN @FromDate <= @MaxCommDate THEN DATEADD(DAY, 1, @MaxCommDate) ELSE @FromDate END
			SELECT @tempToDate		= @ToDate
			
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
				@AffIds				= @AffId,
				@FromMonthDate		= @tempFromDate,
				@ToMonthDate		= @tempToDate,
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END

	END

	-- Return data
	BEGIN
		CREATE TABLE #Result
		(
			AffId				INT,
			Username			NVARCHAR(30),
			GroupId				INT,
			GroupName			NVARCHAR(100),
			TotalPlayers		INT,
			CommissionRate		MONEY,
			IsMultiGroupProduct BIT,
			Earning				MONEY,
			P2PEarning			MONEY,
			SubAffEarning		MONEY
		)
		INSERT INTO #Result
		(
			AffId,
			Username,
			GroupId,
			GroupName,
			CommissionRate,
			IsMultiGroupProduct,
			Earning,
			P2PEarning,
			SubAffEarning
		)
		SELECT
			ai.AffId,
			ai.Username,
			g.GroupId,
			g.GroupName,
			ISNULL(tc.CommissionRate, 0)		AS CommissionRate,
			ISNULL(tc.IsMultiGroupProduct, 0)   AS IsMultiGroupProduct,
			ISNULL(tc.Commission, 0)			AS Earning,
			ISNULL(tc.StraightCommission, 0)	AS P2PEarning,
			ISNULL(tc.SubAffCommission, 0)		AS SubAffEarning
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			LEFT JOIN dbo.CommGroup g WITH(NOLOCK) ON g.GroupId = ai.GroupId
			LEFT JOIN (
				SELECT AffId,
					SUM(CommissionRate)	AS CommissionRate,
					CONVERT(BIT, MAX(CONVERT(TINYINT, IsMultiGroupProduct))) AS IsMultiGroupProduct,
					SUM(Commission)					AS Commission,
					SUM(StraightCommission)			AS StraightCommission,
					SUM(SubAffCommission)			AS SubAffCommission
				FROM #TempCommission
				GROUP BY AffId
			) tc ON ai.AffId = tc.AffId
		WHERE ai.Status = 'Approved' AND ai.AffId = @AffId
	END

	UPDATE r
		SET r.TotalPlayers = n.NumberOfPlayer
	FROM #Result r
	CROSS APPLY (
		SELECT COUNT(1) AS NumberOfPlayer
		FROM MemberInfo m WITH(NOLOCK)
		WHERE m.IsRemoved = 0 AND m.AffId = r.AffId
	) AS n

	SELECT 
		AffId
		,Username AS AffName
		,GroupName
		,TotalPlayers
		,CommissionRate
		,Earning + P2PEarning + SubAffEarning AS [TotalEarning]
	FROM #Result
	ORDER BY Username ASC

	DROP TABLE #TempCommission
	DROP TABLE #Result
END
GO