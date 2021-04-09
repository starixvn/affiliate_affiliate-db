/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task:
		User site - Statement History - Daily Earning
		Admin site - Customer - Statement History - Daily Earning

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
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
		DECLARE @ProductIds VARCHAR(MAX)
		SELECT  @ProductIds = COALESCE(@ProductIds + ',', '') + CONVERT(VARCHAR(15), ProductId)
		FROM (
		SELECT DISTINCT dsh.ProductId
			FROM dbo.AffGroupHistory agh WITH (NOLOCK)
				INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupID = dsh.GroupID AND agh.MonthDate = dsh.MonthDate
			WHERE dsh.ProductId > 0
				AND agh.MonthDate = @EndOfMonth
				AND agh.AffID = @AffId
		) s

		CREATE TABLE #Data
		(
			WinlostDate SMALLDATETIME
			,Deposit	MONEY
			,Withdrawal	MONEY
			,Winloss	MONEY
			,Bonus		MONEY
			,Rebate		MONEY
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

		-- rptMemberDaily
		BEGIN
			INSERT INTO #Data (WinlostDate, Deposit, Withdrawal, Winloss, Bonus, Rebate)
			SELECT r.WinlostDate, SUM(r.Deposit), SUM(r.Withdrawal), SUM(r.Winloss), SUM(r.Bonus), SUM(r.Rebate)
			FROM @tblWinlostDate wld
				CROSS APPLY (
					SELECT	r.WinlostDate
							,r.Deposit * e.Rate				AS Deposit
							,r.Withdrawal * e.Rate			AS Withdrawal
							,r.Winloss * e.Rate				AS Winloss
							,r.Bonus * e.Rate				AS Bonus
							,ISNULL(r.Rebate, 0) * e.Rate	AS Rebate
					FROM dbo.rptMemberDaily r WITH (NOLOCK)
						CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, r.Currency, @BaseCurrency) e
					WHERE r.WinlostDate = wld.WinlostDate
						AND r.AffId = @AffId
						AND (
							r.ProductId < 0
							OR (
								',' + @ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(15), r.ProductId) + ',%'
								AND (@ProductId = 0 OR r.ProductId = @ProductId)
							)
						)
						AND (@Currencies = '' OR ',' + @Currencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
						AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.CustId = r.CustId
								AND mr.RemovedDate <= @EndOfMonth
						)
				) r
			GROUP BY r.WinlostDate
		END
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
			,SUM(ISNULL(Rebate, 0))		AS Rebate
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
			,SUM(ISNULL(Rebate, 0))		AS Rebate
		FROM #Data
		HAVING SUM(ISNULL(Deposit, 0)) IS NOT NULL
	END

	DROP TABLE #Data
END
GO