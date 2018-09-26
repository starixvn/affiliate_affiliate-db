/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

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
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromBeginMonth SMALLDATETIME, @ToEndMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToEndMonth		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
	
	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME

	CREATE TABLE #Data
	(
		WinlostDate SMALLDATETIME,
		Deposit		MONEY,
		Withdrawal	MONEY,
		Winloss		MONEY,
		Bonus		MONEY
	)

	-- Old data
	IF @FromBeginMonth <= @CutOffDate
	BEGIN
		SELECT @tmpFromDate = @FromBeginMonth
		SELECT @tmpToDate = CASE WHEN @ToEndMonth > @CutOffDate THEN @CutOffDate ELSE @ToEndMonth END

		INSERT INTO #Data
		(
			WinlostDate,
			Deposit,
			Withdrawal,
			Winloss,
			Bonus
		)
		SELECT
			md.WinlostDate,
			SUM(ISNULL(Deposit, 0)		* ISNULL(md.AffExRate, 0))	AS Deposit,
			SUM(ISNULL(Withdrawal, 0)	* ISNULL(md.AffExRate, 0))	AS Withdrawal,
			SUM(CASE WHEN ISNULL(@ProductId, 0) = 0 OR md.SportType = @ProductId
				THEN ISNULL(Winlost, 0) * ISNULL(md.AffExRate, 0)
						ELSE 0 END)									AS Winloss,
			SUM(ISNULL(Bonus, 0)		* ISNULL(md.AffExRate, 0))	AS Bonus
		FROM dbo.MemberDaily md WITH (NOLOCK)
		WHERE AffId = @AffId
			AND WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.IBCCustId = md.IBCCustId
					AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
			)
		GROUP BY
			md.WinlostDate
	END
	
	-- New data
	IF @ToEndMonth > @CutOffDate
	BEGIN
		SELECT @tmpFromDate = CASE WHEN @FromBeginMonth <= @CutOffDate THEN DATEADD(DAY, 1, @CutOffDate) ELSE @FromBeginMonth END
		SELECT @tmpToDate = @ToEndMonth
		
		-- rptMemberDaily
		IF (
			@ProductId = 0
			OR EXISTS (
				SELECT 1 FROM dbo.Products WITH (NOLOCK)
				WHERE ProductId = @ProductId
					AND (IsIBC = 0 OR @FromBeginMonth <= @MoveBetsDay)
			)
		)
		BEGIN
			INSERT INTO #Data
			(
				WinlostDate,
				Deposit,
				Withdrawal,
				Winloss,
				Bonus
			)
			SELECT
				md.WinlostDate,
				SUM(ISNULL(Deposit, 0)		* ISNULL(md.AffExRate, 0)) AS Deposit,
				SUM(ISNULL(Withdrawal, 0)	* ISNULL(md.AffExRate, 0)) AS Withdrawal,
				SUM(ISNULL(Winloss, 0)		* ISNULL(md.AffExRate, 0)) AS Winloss,
				SUM(ISNULL(Bonus, 0)		* ISNULL(md.AffExRate, 0)) AS Bonus
			FROM dbo.rptMemberDaily md WITH (NOLOCK)
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 0, md.Winlostdate, @MoveBetsDay) f
			WHERE AffId = @AffId
				AND WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
				AND (@ProductId = 0 OR md.ProductId < 0 OR md.ProductId = @ProductId)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.IBCCustId = md.IBCCustId
						AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
				)
			GROUP BY
				md.WinlostDate
		END

		-- bettrans
		IF (
			@ProductId = 0
			OR EXISTS (
				SELECT 1 FROM dbo.Products WITH (NOLOCK)
				WHERE ProductId = @ProductId
					AND (IsIBC = 1 AND @ToEndMonth > @MoveBetsDay)
			)
		)
		BEGIN
			DECLARE @AffIds VARCHAR(MAX), @ProductIds VARCHAR(MAX)
			SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId), @ProductIds = CONVERT(VARCHAR(5), @ProductId)

			SELECT @tmpFromDate = CASE WHEN @FromBeginMonth <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromBeginMonth END
			SELECT @tmpToDate = @ToEndMonth
			
			INSERT INTO #Data
			(
				WinlostDate,
				Deposit,
				Withdrawal,
				Winloss,
				Bonus
			)
			SELECT
				md.WinlostDate,
				SUM(ISNULL(md.Deposit, 0)	* ISNULL(e.ActualRate2, 0)),
				SUM(ISNULL(md.Withdrawal, 0)* ISNULL(e.ActualRate2, 0)),
				SUM(ISNULL(md.Winloss, 0)	* ISNULL(e.ActualRate2, 0)),
				SUM(ISNULL(md.Bonus, 0)		* ISNULL(e.ActualRate2, 0))
			FROM bodb02.dbo.Aff_f_Bettrans_Sel(@AffIds, @tmpFromDate, @tmpToDate, @ProductIds) md
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
			WHERE NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.IBCCustId = mi.IBCCustId
						AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
				)
			GROUP BY
				md.WinlostDate
		END
	END

	-- Get Banking Fee
	DECLARE @BankingFee DECIMAL(9,8)
	SELECT  @BankingFee = dsh.DeductedPercentage
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
	WHERE agh.AffId = @AffId AND agh.MonthDate = @ToEndMonth
		AND dsh.DeductionID = 12 -- Banking Fee
	
	-- Return data
	BEGIN
		-- Detail
		SELECT
			WinlostDate,
			SUM(ISNULL(Deposit, 0))		AS Deposit,
			SUM(ISNULL(Withdrawal, 0))	AS Withdrawal,
			SUM(ISNULL(Winloss, 0))		AS MemberWinlost,
			SUM(ISNULL(Winloss, 0))		AS MemberWinlostFake,
			SUM(ISNULL(Bonus, 0))		AS Bonus,
			SUM((ISNULL(Deposit, 0) + ISNULL(Withdrawal, 0)) * ISNULL(@BankingFee, 0)) AS BankingFee
		FROM #Data
		GROUP BY
			WinlostDate
		ORDER BY WinlostDate

		-- Sum
		SELECT
			SUM(ISNULL(Deposit, 0))		AS Deposit,
			SUM(ISNULL(Withdrawal, 0))	AS Withdrawal,
			SUM(ISNULL(Winloss, 0))		AS MemberWinlost,
			SUM(ISNULL(Winloss, 0))		AS MemberWinlostFake,
			SUM(ISNULL(Bonus, 0))		AS Bonus,
			SUM((ISNULL(Deposit, 0) + ISNULL(Withdrawal, 0)) * ISNULL(@BankingFee, 0)) AS BankingFee
		FROM #Data
		HAVING SUM(ISNULL(Deposit, 0)) IS NOT NULL
	END

	DROP TABLE #Data
END
GO