/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_Detail_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
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

	-- Signups, Deposited Members
	BEGIN
		DECLARE @Signups TABLE (WinlostDate SMALLDATETIME, Signups INT DEFAULT(0), DepositedMembers INT DEFAULT(0))

		INSERT INTO @Signups (WinlostDate, Signups)
		SELECT CONVERT(DATE, RegisteredDate) AS WinlostDate, COUNT(1) AS Signups
		FROM dbo.MemberInfo WITH (NOLOCK)
		WHERE AffId = @AffId
			AND RegisteredDate >= @FromBeginMonth AND RegisteredDate < @ToNextMonth
		GROUP BY CONVERT(DATE, RegisteredDate)

		INSERT INTO @Signups (WinlostDate, DepositedMembers)
		SELECT CONVERT(DATE, FirstDepositDate) AS WinlostDate, COUNT(1) AS DepositedMembers
		FROM dbo.MemberInfo WITH (NOLOCK)
		WHERE AffId = @AffId
			AND FirstDepositDate >= @FromBeginMonth AND FirstDepositDate < @ToNextMonth
		GROUP BY CONVERT(DATE, FirstDepositDate)
	END

	-- Turnover, Winloss, Deposit, Withdrawl, Active Members, Qualified Active Members
	BEGIN
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

		CREATE TABLE #Data (WinlostDate SMALLDATETIME, CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, Winloss MONEY)
		
		INSERT INTO #Data (WinlostDate, CustId, Deposit, Withdrawal, Turnover, Winloss)
		SELECT r.WinlostDate, r.CustId, SUM(r.Deposit), SUM(r.Withdrawal), SUM(r.Turnover), SUM(r.Winloss)
		FROM @tblWinlostDate wld
			CROSS APPLY (
				SELECT	r.WinlostDate, r.CustId
						,r.Deposit		* ISNULL(e.Rate, 1) AS Deposit
						,r.Withdrawal	* ISNULL(e.Rate, 1) AS Withdrawal
						,r.Turnover		* ISNULL(e.Rate, 1) AS Turnover
						,r.Winloss		* ISNULL(e.Rate, 1) AS Winloss
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (r.WinlostDate, r.Currency, @BaseCurrency) e
				WHERE r.WinlostDate = wld.WinlostDate
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId
							AND mr.RemovedDate <= @EndOfMonth
					)
			) r
		GROUP BY r.WinlostDate, r.CustId

		CREATE CLUSTERED INDEX CIX_IBCCustId_WinlostDate ON #Data (CustId, WinlostDate)

		-- Active Members
		DECLARE @ActiveMembers TABLE (WinlostDate SMALLDATETIME, CustId INT)

		DECLARE @tmpWinlostDate SMALLDATETIME
		SELECT  @tmpWinlostDate = @FromBeginMonth

		WHILE @tmpWinlostDate < @ToNextMonth
		BEGIN
			IF EXISTS (SELECT 1 FROM #Data WHERE WinlostDate = @tmpWinlostDate)
			BEGIN
				INSERT INTO @ActiveMembers (WinlostDate, CustId)
				SELECT WinlostDate, CustId
				FROM #Data d
				WHERE WinlostDate = @tmpWinlostDate
					AND Turnover > 0
					AND NOT EXISTS (SELECT 1 FROM @ActiveMembers a WHERE d.CustId = a.CustId)
			END

			SELECT @tmpWinlostDate = DATEADD(DAY, 1, @tmpWinlostDate)
		END
	END
	
	-- Return result
	BEGIN
		SELECT
			wld.WinlostDate
			,ISNULL(s.Signups, 0)					AS Signups
			,ISNULL(s.DepositedMembers, 0)			AS DepositedMembers
			,ISNULL(d.Deposit, 0)					AS Deposit
			,ISNULL(d.Withdrawal, 0)				AS Withdrawal
			,ISNULL(d.Turnover, 0)					AS Turnover
			,ISNULL(d.Winloss, 0)					AS Winloss
			,ISNULL(a.ActiveMembers, 0)				AS ActiveMembers
			,ISNULL(a.ActiveMembers, 0)				AS QualifiedActiveMembers
		FROM @tblWinlostDate wld
			OUTER APPLY (
				SELECT SUM(s.Signups) AS Signups, SUM(s.DepositedMembers) AS DepositedMembers
				FROM @Signups s
				WHERE wld.WinlostDate = s.WinlostDate
			) s
			OUTER APPLY (
				SELECT SUM(d.Deposit) AS Deposit, SUM(d.Withdrawal) AS Withdrawal, SUM(d.Turnover) AS Turnover, SUM(d.Winloss) AS Winloss
				FROM #Data d
				WHERE wld.WinlostDate = d.WinlostDate
			) d
			OUTER APPLY (
				SELECT COUNT(DISTINCT a.CustId) AS ActiveMembers
				FROM @ActiveMembers a
				WHERE wld.WinlostDate = a.WinlostDate
			) a
		ORDER BY wld.WinlostDate DESC
	END

	DROP TABLE #Data
END
GO