/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_Detail_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Treat TO, WL = 0 for P2P Products [RedmineID: #157958]
		- 20210916@Percy: Change WL to GGR [RedmineID: #161540]
		- 20211105@Percy: Exclude non-deposited player from active players [RedmineID: #164246]
		- 20220110@Percy: Fix check current date due to different timezone [RedmineID: #167244]
		- 20220629@Malcolm: Support an Affiliate remove player [RedmineID: #173640]
		- 20230523@Sally: Support Currency BDT, USD 72 [RedmineID: #188429]
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, @ToNextMonth)

	DECLARE @TimeZone INT
	SELECT  @TimeZone = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'

	IF @ToNextMonth > DATEADD(DAY, 1, CONVERT(DATE, DATEADD(HOUR, 4 + @TimeZone, GETDATE())))
		SELECT @ToNextMonth = DATEADD(DAY, 1, CONVERT(DATE, DATEADD(HOUR, 4 + @TimeZone, GETDATE())))

	IF @ToNextMonth < DATEADD(DAY, 1, @FromBeginMonth)
		RETURN

	--Get BaseCurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	DECLARE @Products TABLE (ProductId INT, IsStraightSetting BIT)
		
	INSERT INTO @Products (ProductId, IsStraightSetting)
	SELECT DISTINCT dsh.ProductId, 0
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.ProductId > 0
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

	INSERT INTO @Products (ProductId, IsStraightSetting)
	SELECT DISTINCT ssh.ProductId, 1
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON agh.GroupId = ssh.GroupId AND agh.MonthDate = ssh.MonthDate
	WHERE ssh.ProductId > 0
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

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

	-- Turnover, Winloss, Deposit, Withdrawl, Qualified Active Members
	BEGIN
		CREATE TABLE #Data (WinlostDate SMALLDATETIME, CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, GGR MONEY, IsActive TINYINT)
		
		INSERT INTO #Data (WinlostDate, CustId, Deposit, Withdrawal, Turnover, GGR, IsActive)
		SELECT r.WinlostDate, r.CustId
			,SUM(r.Deposit * e.Rate) AS Deposit
			,SUM(r.Withdrawal * e.Rate) AS Withdrawal
			,SUM(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate) AS Turnover
			,SUM(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
					ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate) AS GGR
			,MAX(CASE WHEN r.ProductId > 0 THEN 1 ELSE 0 END)
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
			LEFT JOIN @Products p ON r.ProductId = p.ProductId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (r.WinlostDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
		WHERE r.WinlostDate BETWEEN @FromBeginMonth AND @ToNextMonth
			AND r.AffId = @AffId
			AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)
		GROUP BY r.WinlostDate, r.CustId

		CREATE CLUSTERED INDEX CIX_IBCCustId_WinlostDate ON #Data (CustId, WinlostDate)

		UPDATE d
		SET d.IsActive = 0
		FROM #Data d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
		WHERE d.IsActive = 1
			AND (
				m.FirstDepositDate IS NULL
				OR m.FirstDepositDate >= DATEADD(DAY, 1, @EndOfMonth)
			)

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
					AND IsActive = 1
					AND NOT EXISTS (SELECT 1 FROM @ActiveMembers a WHERE d.CustId = a.CustId)
			END

			SELECT @tmpWinlostDate = DATEADD(DAY, 1, @tmpWinlostDate)
		END
	END
	
	-- Return result
	BEGIN
		WITH CTE_WinlostDate AS (
			SELECT @FromBeginMonth AS WinlostDate
			UNION ALL
			SELECT DATEADD(DAY, 1, WinlostDate)
			FROM CTE_WinlostDate
			WHERE WinlostDate < DATEADD(DAY, -1, @ToNextMonth)
		)
		SELECT
			wld.WinlostDate
			,ISNULL(s.Signups, 0)			AS Signups
			,ISNULL(s.DepositedMembers, 0)	AS DepositedMembers
			,ISNULL(d.Deposit, 0)			AS Deposit
			,ISNULL(d.Withdrawal, 0)		AS Withdrawal
			,ISNULL(d.Turnover, 0)			AS Turnover
			,ISNULL(d.GGR, 0)				AS GGR
			,ISNULL(a.ActiveMembers, 0)		AS ActiveMembers
		FROM CTE_WinlostDate wld
			OUTER APPLY (
				SELECT SUM(s.Signups) AS Signups, SUM(s.DepositedMembers) AS DepositedMembers
				FROM @Signups s
				WHERE wld.WinlostDate = s.WinlostDate
			) s
			OUTER APPLY (
				SELECT SUM(d.Deposit) AS Deposit, SUM(d.Withdrawal) AS Withdrawal, SUM(d.Turnover) AS Turnover, SUM(d.GGR) AS GGR
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