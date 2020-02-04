/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Detail_Sel]
	@AffId		INT,
	@ProductId	INT = 0,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task:
		User site - Statement History - Daily Earning - Detail
		Admin site - Customer - Statement History - Daily Earning - Detail

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20191210@Percy: Remove get data on bettrans [RedmineID: #121971]
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
		CREATE TABLE #Data
		(
			IBCCustId	INT
			,Deposit	MONEY
			,Withdrawal	MONEY
			,Turnover	MONEY
			,Winloss	MONEY
			,Bonus		MONEY
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
			INSERT INTO #Data (IBCCustId, Deposit, Withdrawal, Turnover, Winloss, Bonus)
			SELECT r.IBCCustId, SUM(r.Deposit), SUM(r.Withdrawal), SUM(r.Turnover), SUM(r.Winloss), SUM(r.Bonus)
			FROM @tblWinlostDate wld
				CROSS APPLY (
					SELECT	r.IBCCustId
							,r.Deposit * r.AffExRate	AS Deposit
							,r.Withdrawal * r.AffExRate AS Withdrawal
							,CASE WHEN ISNULL(@ProductId, 0) = 0 OR r.SportType = @ProductId THEN r.Turnover * r.AffExRate ELSE 0 END AS Turnover
							,CASE WHEN ISNULL(@ProductId, 0) = 0 OR r.SportType = @ProductId THEN r.Winlost * r.AffExRate ELSE 0 END AS Winloss
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
			GROUP BY r.IBCCustId
		END
		-- rptMemberDaily
		ELSE
		BEGIN
			INSERT INTO #Data (IBCCustId, Deposit, Withdrawal, Turnover, Winloss, Bonus)
			SELECT r.IBCCustId, SUM(r.Deposit), SUM(r.Withdrawal), SUM(r.Turnover), SUM(r.Winloss), SUM(r.Bonus)
			FROM @tblWinlostDate wld
				CROSS APPLY (
					SELECT	r.IBCCustId
							,r.Deposit * r.AffExRate	AS Deposit
							,r.Withdrawal * r.AffExRate AS Withdrawal
							,r.Turnover * r.AffExRate	AS Turnover
							,r.Winloss * r.AffExRate	AS Winloss
							,r.Bonus * r.AffExRate		AS Bonus
					FROM dbo.rptMemberDaily r WITH (NOLOCK)
					WHERE r.WinlostDate = wld.WinlostDate
						AND r.AffId = @AffId
						AND (@ProductId = 0 OR r.ProductId < 0 OR r.ProductId = @ProductId)
						AND NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE mr.IBCCustId = r.IBCCustId
								AND mr.RemovedDate <= @EndOfMonth
						)
				) r
			GROUP BY r.IBCCustId
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
		SELECT
			mi.IBCCustId					AS CustId
			,mi.UserName
			,mi.IBCUsername
			,SUM(ISNULL(dt.Deposit, 0))		AS Deposit
			,SUM(ISNULL(dt.Withdrawal, 0))	AS Withdrawal
			,SUM(ISNULL(dt.Turnover, 0))	AS Turnover
			,SUM(ISNULL(dt.Winloss, 0))		AS Winlost
			,SUM(ISNULL(dt.Bonus, 0))		AS Bonus
			,SUM((ISNULL(dt.Deposit, 0) + ISNULL(dt.Withdrawal, 0)) * ISNULL(@BankingFee, 0)) AS BankingFee
		FROM #Data dt
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON dt.IBCCustId = mi.IBCCustId
		GROUP BY
			mi.IBCCustId,
			mi.UserName,
			mi.IBCUsername
		ORDER BY
			mi.UserName
	END

	DROP TABLE #Data
END
GO