/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_Detail_Sel]
	@AffId		INT,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20191210@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121971]
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

	DECLARE @QMTurnover MONEY
	
	SELECT  @QMTurnover = QMTurnover
	FROM dbo.CommGroupHistory cgh WITH (NOLOCK)
		INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK) ON cgh.GroupID = agh.GroupID AND cgh.MonthDate = agh.MonthDate
	WHERE cgh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId
	
	SELECT  @QMTurnover = ISNULL(@QMTurnover, 0)

	-- Signups, Deposited Members
	BEGIN
		DECLARE @Signups TABLE (WinlostDate SMALLDATETIME, Signups INT, DepositedMembers INT)

		INSERT INTO @Signups (WinlostDate, Signups, DepositedMembers)
		SELECT CONVERT(DATE, creatdate) AS WinlostDate, COUNT(1) AS Signups, COUNT(IBCCustID) AS DepositedMembers
		FROM DBDEPOSIT.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
		WHERE AffiliateID = @AffId
			AND creatdate >= @FromBeginMonth AND creatdate < @ToNextMonth
		GROUP BY CONVERT(DATE, creatdate)
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

		CREATE TABLE #Data (WinlostDate SMALLDATETIME, IBCCustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, Winloss MONEY)
		
		INSERT INTO #Data (WinlostDate, IBCCustId, Deposit, Withdrawal, Turnover, Winloss)
		SELECT r.WinlostDate, r.IBCCustId, SUM(r.Deposit), SUM(r.Withdrawal), SUM(r.Turnover), SUM(r.Winloss)
		FROM @tblWinlostDate wld
			CROSS APPLY (
				SELECT	r.WinlostDate, r.IBCCustId
						,r.Deposit * r.AffExRate	AS Deposit
						,r.Withdrawal * r.AffExRate AS Withdrawal
						,r.Turnover * r.AffExRate	AS Turnover
						,r.Winloss * r.AffExRate	AS Winloss
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate = wld.WinlostDate
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.IBCCustId = r.IBCCustId
							AND mr.RemovedDate <= @EndOfMonth
					)
			) r
		GROUP BY r.WinlostDate, r.IBCCustId

		CREATE CLUSTERED INDEX CIX_IBCCustId_WinlostDate ON #Data (IBCCustId, WinlostDate)

		-- Active Members, Qualified Active Members
		DECLARE @ActiveMembers TABLE (WinlostDate SMALLDATETIME, IBCCustId INT)
		DECLARE @QualifiedActiveMembers TABLE (WinlostDate SMALLDATETIME, IBCCustId INT, Turnover MONEY)

		DECLARE @tmpWinlostDate SMALLDATETIME
		SELECT  @tmpWinlostDate = @FromBeginMonth

		WHILE @tmpWinlostDate < @ToNextMonth
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM #Data WHERE WinlostDate = @tmpWinlostDate)
				BREAK

			INSERT INTO @ActiveMembers (WinlostDate, IBCCustId)
			SELECT WinlostDate, IBCCustId
			FROM #Data d
			WHERE WinlostDate = @tmpWinlostDate
				AND (Deposit > 0 OR Turnover > 0)
				AND NOT EXISTS (SELECT 1 FROM @ActiveMembers a WHERE d.IBCCustId = a.IBCCustId)

			INSERT INTO @QualifiedActiveMembers (WinlostDate, IBCCustId, Turnover)
			SELECT @tmpWinlostDate AS WinlostDate, IBCCustId, SUM(Turnover) AS Turnover
			FROM #Data d
			WHERE WinlostDate <= @tmpWinlostDate
				AND NOT EXISTS (SELECT 1 FROM @QualifiedActiveMembers q WHERE d.IBCCustId = q.IBCCustId)
			GROUP BY IBCCustId
			HAVING SUM(Turnover) >= @QMTurnover

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
			,ISNULL(q.QualifiedActiveMembers, 0)	AS QualifiedActiveMembers
		FROM @tblWinlostDate wld
			OUTER APPLY (
				SELECT s.Signups, s.DepositedMembers
				FROM @Signups s
				WHERE wld.WinlostDate = s.WinlostDate
			) s
			OUTER APPLY (
				SELECT SUM(d.Deposit) AS Deposit, SUM(d.Withdrawal) AS Withdrawal, SUM(d.Turnover) AS Turnover, SUM(d.Winloss) AS Winloss
				FROM #Data d
				WHERE wld.WinlostDate = d.WinlostDate
			) d
			OUTER APPLY (
				SELECT COUNT(DISTINCT a.IBCCustID) AS ActiveMembers
				FROM @ActiveMembers a
				WHERE wld.WinlostDate = a.WinlostDate
			) a
			OUTER APPLY (
				SELECT COUNT(DISTINCT q.IBCCustID) AS QualifiedActiveMembers
				FROM @QualifiedActiveMembers q
				WHERE wld.WinlostDate = q.WinlostDate
			) q
		ORDER BY wld.WinlostDate DESC
	END

	DROP TABLE #Data
END
GO