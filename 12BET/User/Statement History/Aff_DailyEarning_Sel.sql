/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Sel]
	@AffId		INT,
	@ProductId	INT = 0,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task:
		User site - Statement History - Daily Earning
		Admin site - Customer - Statement History - Daily Earning

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20191210@Percy: Remove get data on bettrans [RedmineID: #121971]
		- 20210526@Malcolm: Get turnover [RedmineID: #149210]
		- 20211207@Percy: Apply core function Group Product [RedmineID: #165777]
		- 20240325@Eddie: Merge VS2 into Virtual Sports and change metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #201095]
		- 20240611@Eddie: Add new Product VS3&4 and change metadata "wsv_aff,wsv_affv" [RedmineId : #206363]
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, @ToNextMonth)

	IF @ToNextMonth > DATEADD(DAY, 1, CONVERT(DATE, GETDATE()))
		SELECT @ToNextMonth = DATEADD(DAY, 1, CONVERT(DATE, GETDATE()))

	IF @ToNextMonth < DATEADD(DAY, 1, @FromBeginMonth)
		RETURN

	-- Get Data
	BEGIN
		DECLARE @Products TABLE (ProductId INT)
	
		IF @ProductId > 0
			INSERT INTO @Products (ProductId)
			SELECT ISNULL(g.ProductId, p.ProductId)
			FROM dbo.Products p WITH (NOLOCK)
				LEFT JOIN dbo.Aff_f_GroupProduct() g ON p.ProductId = g.GroupProductId
			WHERE p.ProductId = @ProductId

		CREATE TABLE #Data
		(
			WinlostDate SMALLDATETIME
			,Deposit	MONEY
			,Withdrawal	MONEY
			,Winloss	MONEY
			,Bonus		MONEY
			,Turnover   MONEY
		)

		DECLARE @tblWinlostDate TABLE (WinlostDate SMALLDATETIME)
		;WITH CTE AS (
			SELECT @FromBeginMonth AS WinlostDate
			UNION ALL
			SELECT DATEADD(DAY, 1, WinlostDate)
			FROM CTE
			WHERE WinlostDate < DATEADD(DAY, -1, @ToNextMonth)
		)
		INSERT INTO @tblWinlostDate (WinlostDate)
		SELECT WinlostDate FROM CTE
		OPTION (MAXRECURSION 0)

		DECLARE @CutOffDate SMALLDATETIME
		SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

		-- MemberDaily
		IF EXISTS (SELECT 1 FROM @tblWinlostDate WHERE WinlostDate = @CutOffDate)
		BEGIN
			INSERT INTO #Data (WinlostDate, Deposit, Withdrawal, Winloss, Bonus, Turnover)
			SELECT r.WinlostDate, SUM(r.Deposit), SUM(r.Withdrawal), SUM(r.Winloss), SUM(r.Bonus), SUM(r.Turnover)
			FROM @tblWinlostDate wld
				CROSS APPLY (
					SELECT	r.WinlostDate
							,r.Deposit * r.AffExRate	AS Deposit
							,r.Withdrawal * r.AffExRate AS Withdrawal
							,CASE WHEN ISNULL(@ProductId, 0) = 0 OR r.SportType = @ProductId THEN r.Winlost * r.AffExRate ELSE 0 END AS Winloss
							,CASE WHEN ISNULL(@ProductId, 0) = 0 OR r.SportType = @ProductId THEN r.Turnover * r.AffExRate ELSE 0 END AS Turnover
							,r.Bonus * r.AffExRate		AS Bonus					
					FROM dbo.MemberDaily r WITH (NOLOCK)
					WHERE r.WinlostDate = wld.WinlostDate
						AND r.AffId = @AffId
						AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = r.IBCCustId
								AND mr.RemovedDate <= @EndOfMonth
						)
				) r
			GROUP BY r.WinlostDate
		END
		-- rptMemberDaily
		ELSE
		BEGIN
			INSERT INTO #Data (WinlostDate, Deposit, Withdrawal, Winloss, Bonus, Turnover)
			SELECT r.WinlostDate, SUM(r.Deposit), SUM(r.Withdrawal), SUM(r.Winloss), SUM(r.Bonus), SUM(r.Turnover)
			FROM @tblWinlostDate wld
				CROSS APPLY (
					SELECT	r.WinlostDate
							,r.Deposit * r.AffExRate	AS Deposit
							,r.Withdrawal * r.AffExRate AS Withdrawal
							,r.Winloss * r.AffExRate	AS Winloss
							,r.Bonus * r.AffExRate		AS Bonus
							,r.Turnover * r.AffExRate   AS Turnover
					FROM dbo.rptMemberDaily r WITH (NOLOCK)
						LEFT JOIN @Products p ON r.ProductId = p.ProductId
					WHERE r.WinlostDate = wld.WinlostDate
						AND r.AffId = @AffId
						AND (@ProductId = 0 OR r.ProductId < 0 OR p.ProductId IS NOT NULL)
						AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = r.IBCCustId
								AND mr.RemovedDate <= @EndOfMonth
						)
				) r
			GROUP BY r.WinlostDate
		END

		-- Get Banking Fee
		DECLARE @BankingFee DECIMAL(9,8)
		SELECT  @BankingFee = dsh.DeductedPercentage
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
		WHERE agh.AffId = @AffId AND agh.MonthDate = @EndOfMonth
			AND dsh.DeductionID = 12 -- Banking Fee
	END
	
	-- Return data
	BEGIN
		-- Detail
		SELECT
			WinlostDate
			,SUM(ISNULL(Deposit, 0))	AS Deposit
			,SUM(ISNULL(Withdrawal, 0))	AS Withdrawal
			,SUM(ISNULL(Winloss, 0))	AS MemberWinlost
			,SUM(ISNULL(Winloss, 0))	AS MemberWinlostFake
			,SUM(ISNULL(Bonus, 0))		AS Bonus
			,SUM((ISNULL(Deposit, 0) + ISNULL(Withdrawal, 0)) * ISNULL(@BankingFee, 0)) AS BankingFee
			,SUM(ISNULL(Turnover, 0))   AS Turnover
		FROM #Data
		GROUP BY
			WinlostDate
		ORDER BY WinlostDate

		-- Sum
		SELECT
			SUM(ISNULL(Deposit, 0))		AS Deposit
			,SUM(ISNULL(Withdrawal, 0))	AS Withdrawal
			,SUM(ISNULL(Winloss, 0))	AS MemberWinlost
			,SUM(ISNULL(Winloss, 0))	AS MemberWinlostFake
			,SUM(ISNULL(Bonus, 0))		AS Bonus
			,SUM((ISNULL(Deposit, 0) + ISNULL(Withdrawal, 0)) * ISNULL(@BankingFee, 0)) AS BankingFee
			,SUM(ISNULL(Turnover, 0))   AS Turnover
		FROM #Data
		HAVING SUM(ISNULL(Deposit, 0)) IS NOT NULL
	END

	DROP TABLE #Data
END
GO