/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_EarningSelDaily] 
	@AffID					INT,
	@SportType				TINYINT = 0,
	@monthdate				SMALLDATETIME,
	@MarketingPercent		FLOAT = 0 OUTPUT,
	@OddsFeePercent			FLOAT = 0 OUTPUT,
	@PSPFeePercent			FLOAT = 0 OUTPUT,
	@CasinoMarketingPercent FLOAT = 0 OUTPUT,
	@PLayTechFeePercent		FLOAT = 0 OUTPUT
AS

/*
	Created: 200900911@VinhTrinh 
	Task : [description of SP]  
	DB: DBAFF12BET.Affiliate_12BET
	
	Revisions:  		
		- Get data for daily report from table AffDaily instead of MemberDaily
		- 20100520@Johnny: apply StatusID in bettrans table
		- 20100930@Peter: Change the new formula for displayed winlost
					Winlost on Aff site=Winlost-Odds Management - Marketing cost -  PSP
					--The formula change since 1 Oct 2010--need to consider a new column MemWinlostFake on MemberDaily table if it is changed again
					MemWinlostFake need to be updated on TaskMemberDaily
		- 20101228@Henry: change bettype to new range
		- 20111031@Peter: Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20120606@Peter: Exclude waiting tickets
		- 20140403@Bobby: Exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype & fix Casiso time range
		- 20150106@Bobby: Update WL fake
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		- 20180222@Percy: Change range of winlostdate when getting data [RedmineID: #90861]
		- 20180601@Percy: Refactor code for new commission [RedmineID: #87923]

	Param's Explanation:  
		• @custid: affliate Id  
		• @monthdate: Month date need to view.
*/

BEGIN
	SET NOCOUNT ON

	SELECT	@MarketingPercent = 0,
			@OddsFeePercent = 0,
			@PSPFeePercent = 0,
			@CasinoMarketingPercent = 0,
			@PLayTechFeePercent = 0

	DECLARE @ProductId INT
	SELECT  @ProductId = ISNULL(@Sporttype, 0)

	DECLARE @FromBeginMonth SMALLDATETIME, @ToEndMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToEndMonth		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
	
	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME

	DECLARE @tmpDate SMALLDATETIME

	CREATE TABLE #Data
	(
		WinlostDate SMALLDATETIME,
		Deposit		MONEY,
		Withdrawal	MONEY,
		Winloss		MONEY,
		Bonus		MONEY
	)

	-- MemberDaily
	IF @FromBeginMonth < @CutOffDate
	BEGIN
		SELECT @tmpFromDate = @FromBeginMonth
		SELECT @tmpToDate = CASE WHEN @ToEndMonth >= @CutOffDate THEN @CutOffDate ELSE @ToEndMonth END

		-- Deposit, Withdrawal, Bonus
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
			0 AS Winloss,
			SUM(ISNULL(Bonus, 0)		* ISNULL(md.AffExRate, 0)) AS Bonus
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

		-- Winloss
		IF ISNULL(@ProductId, 0) IN (0,1,3)
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
				0 AS Deposit,
				0 AS Withdrawal,
				SUM(ISNULL(Winlost, 0) * ISNULL(md.AffExRate, 0)) AS Winloss,
				0 AS Bonus
			FROM dbo.MemberDaily md WITH (NOLOCK)
			WHERE AffId = @AffId
				AND WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
				AND (ISNULL(@ProductId, 0) = 0 OR md.SportType = @ProductId)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.IBCCustId = md.IBCCustId
						AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
				)
			GROUP BY
				md.WinlostDate
		END
	END

	-- rptMemberDaily
	IF @ToEndMonth >= @CutOffDate
	BEGIN
		SELECT @tmpFromDate = CASE WHEN @FromBeginMonth < @CutOffDate THEN @CutOffDate ELSE @FromBeginMonth END
		SELECT @tmpToDate = @ToEndMonth

		IF (
			@ProductId = 0
			OR EXISTS (
				SELECT 1 FROM dbo.Products WITH (NOLOCK)
				WHERE ProductId = @ProductId
					AND (IsIBC = 0 OR @tmpFromDate <= @MoveBetsDay)
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
				AND (@ProductId = 0 OR md.ProductId = @ProductId)
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
					AND (IsIBC = 1 AND @tmpToDate > @MoveBetsDay)
			)
		)
		BEGIN
			SELECT @tmpDate = CASE WHEN @FromBeginMonth <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromBeginMonth END

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
			FROM OPENQUERY(DBEXT, 'SELECT WinlostDate,IBCCustId,currency,ProductId,Deposit,Withdrawal,Bonus,Turnover,Winloss
									FROM bodb02.dbo.Aff_f_Bettrans_Sel()') md
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
			WHERE md.WinlostDate BETWEEN @tmpDate AND @tmpToDate
				AND mi.AffId = @AffId
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.IBCCustId = mi.IBCCustId
						AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
				)
			GROUP BY
				md.WinlostDate
		END
	END
	
	-- Return data
	BEGIN
		-- Detail
		SELECT
			WinlostDate,
			SUM(ISNULL(Deposit, 0)) AS Deposit,
			SUM(ISNULL(Withdrawal, 0)) AS Withdrawal,
			SUM(ISNULL(Winloss, 0)) AS MemberWinlost,
			SUM(ISNULL(Winloss, 0)) AS MemberWinlostFake,
			SUM(ISNULL(Bonus, 0)) AS Bonus,
			0 AS Adjustment,
			0 AS PSP
		FROM #Data
		GROUP BY
			WinlostDate
		ORDER BY WinlostDate

		-- Sum
		SELECT
			SUM(ISNULL(Deposit, 0)) AS Deposit,
			SUM(ISNULL(Withdrawal, 0)) AS Withdrawal,
			SUM(ISNULL(Winloss, 0)) AS MemberWinlost,
			SUM(ISNULL(Winloss, 0)) AS MemberWinlostFake,
			SUM(ISNULL(Bonus, 0)) AS Bonus,
			0 AS Adjustment,
			0 AS PSP
		FROM #Data
		HAVING SUM(ISNULL(Deposit, 0)) IS NOT NULL
	END

	DROP TABLE #Data
END
GO