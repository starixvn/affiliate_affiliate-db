/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_PlayersDetail_Sel]
	@AffId		INT,
	@ProductId	INT = 0,
	@MonthDate	SMALLDATETIME,
	@PageIndex	INT = 1,
	@PageSize	INT = 200,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task:
		Admin site - Customer - Players Detail
		Admin site - Customer - Statistics - Click amount of Total Active Players

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME

	SELECT	@FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0), -- Begin Month
			@ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0)) -- End Month

	DECLARE @MinReportDate SMALLDATETIME
	SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(@AffId)

	IF @FromDate < @MinReportDate
		SELECT @FromDate = @MinReportDate

	IF @ToDate < @FromDate
		RETURN

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME

	CREATE TABLE #MemberData
	(
		IBCCustId	INT,
		Deposit		MONEY,
		Withdrawal	MONEY,
		BankingFee	MONEY,
		Bonus		MONEY,
		Turnover	MONEY,
		Winloss		MONEY
	)

	-- MemberDaily
	IF @FromDate <= @CutOffDate
	BEGIN
		SELECT @tmpFromDate = @FromDate
		SELECT @tmpToDate = CASE WHEN @ToDate > @CutOffDate THEN @CutOffDate ELSE @ToDate END

		INSERT INTO #MemberData
		(
			IBCCustId,
			Deposit,
			Withdrawal,
			BankingFee,
			Bonus,
			Turnover,
			Winloss
		)
		SELECT
			md.IBCCustId,
			SUM(ISNULL(md.Deposit, 0)		* ISNULL(md.AffExRate, 0)) AS Deposit,
			SUM(ISNULL(md.Withdrawal, 0)	* ISNULL(md.AffExRate, 0)) AS Withdrawal,
			0															AS BankingFee,
			SUM(ISNULL(md.Bonus, 0)			* ISNULL(md.AffExRate, 0)) AS Bonus,
			SUM(CASE WHEN @ProductId = 0 OR md.SportType = @ProductId THEN
				ISNULL(md.Turnover, 0)		* ISNULL(md.AffExRate, 0)
					ELSE 0 END)										   AS Turnover,
			SUM(CASE WHEN @ProductId = 0 OR md.SportType = @ProductId THEN
				ISNULL(md.Winlost, 0)		* ISNULL(md.AffExRate, 0)
					ELSE 0 END)										   AS Winloss
		FROM dbo.MemberDaily md WITH (NOLOCK)
		WHERE md.AffId = @AffId
			AND md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
		GROUP BY
			md.IBCCustId
	END

	-- rptMemberDaily
	IF @ToDate > @CutOffDate
	BEGIN
		SELECT @tmpFromDate = CASE WHEN @FromDate <= @CutOffDate THEN DATEADD(DAY, 1, @CutOffDate) ELSE @FromDate END
		SELECT @tmpToDate = @ToDate

		INSERT INTO #MemberData
		(
			IBCCustId,
			Deposit,
			Withdrawal,
			BankingFee,
			Bonus,
			Turnover,
			Winloss
		)
		SELECT
			md.IBCCustId,
			SUM(ISNULL(md.Deposit, 0)		* ISNULL(md.AffExRate, 0)) AS Deposit,
			SUM(ISNULL(md.Withdrawal, 0)	* ISNULL(md.AffExRate, 0)) AS Withdrawal,
			SUM((ISNULL(md.Deposit, 0) + ISNULL(md.Withdrawal, 0)) * ISNULL(s.BankingFee, 0) * ISNULL(md.AffExRate, 0)) AS BankingFee,
			SUM(ISNULL(md.Bonus, 0)			* ISNULL(md.AffExRate, 0)) AS Bonus,
			SUM(ISNULL(md.Turnover, 0)		* ISNULL(md.AffExRate, 0)) AS Turnover,
			SUM(ISNULL(md.Winloss, 0)		* ISNULL(md.AffExRate, 0)) AS Winloss
		FROM dbo.rptMemberDaily md WITH (NOLOCK)
			CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 0, md.WinlostDate, @MoveBetsDay) f
			CROSS APPLY dbo.Aff_f_GetSettingAll(@AffId, 0, md.WinlostDate) s
		WHERE md.AffId = @AffId
			AND md.WinlostDate BETWEEN @tmpFromDate AND @tmpToDate
			AND (@ProductId = 0 OR md.ProductId = @ProductId OR md.ProductId < 0)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
					AND mr.IBCCustId = md.IBCCustId
			)
		GROUP BY
			md.IBCCustId

		-- bettrans
		IF @ToDate > @MoveBetsDay
		BEGIN
			SELECT @tmpFromDate = CASE WHEN @FromDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromDate END
			SELECT @tmpToDate = @ToDate

			DECLARE @AffIds VARCHAR(MAX)
			SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

			INSERT INTO #MemberData
			(
				IBCCustId,
				Deposit,
				Withdrawal,
				BankingFee,
				Bonus,
				Turnover,
				Winloss
			)
			SELECT
				md.IBCCustId,
				SUM(ISNULL(md.Deposit, 0)		* ISNULL(e.ActualRate2, 0)) AS Deposit,
				SUM(ISNULL(md.Withdrawal, 0)	* ISNULL(e.ActualRate2, 0)) AS Withdrawal,
				SUM((ISNULL(md.Deposit, 0) + ISNULL(md.Withdrawal, 0)) * ISNULL(s.BankingFee, 0) * ISNULL(e.ActualRate2, 0)) AS BankingFee,
				SUM(ISNULL(md.Bonus, 0)			* ISNULL(e.ActualRate2, 0)) AS Bonus,
				SUM(ISNULL(md.Turnover, 0)		* ISNULL(e.ActualRate2, 0)) AS Turnover,
				SUM(ISNULL(md.Winloss, 0)		* ISNULL(e.ActualRate2, 0)) AS Winloss
			FROM dbo.Aff_f_Bettrans_Sel(@AffIds, @tmpFromDate, @tmpToDate, '0') md
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
				CROSS APPLY dbo.Aff_f_GetSettingAll(@AffId, 0, md.WinlostDate) s
			WHERE (@ProductId = 0 OR md.ProductId < 0 OR md.ProductId = @ProductId)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
						AND mr.IBCCustId = md.IBCCustId
				)
			GROUP BY
				md.IBCCustId
		END
	END

	-- Return data
	BEGIN
		CREATE TABLE #Result
		(
			IBCCustId	INT,
			Deposit		MONEY,
			Withdrawal	MONEY,
			BankingFee	MONEY,
			Bonus		MONEY,
			Turnover	MONEY,
			Winloss		MONEY
		)
	
		INSERT INTO #Result
		(
			IBCCustId,
			Deposit,
			Withdrawal,
			BankingFee,
			Bonus,
			Turnover,
			Winloss
		)
		SELECT
			IBCCustId,
			SUM(Deposit),
			SUM(Withdrawal),
			SUM(BankingFee),
			SUM(Bonus),
			SUM(Turnover),
			SUM(Winloss)
		FROM #MemberData
		GROUP BY IBCCustId
		HAVING SUM(Deposit) > 0 OR SUM(Turnover) > 0

		SELECT @NRows = @@ROWCOUNT

		DROP TABLE #MemberData

		-- paging
		DECLARE @RowStart INT, @RowEnd INT

		SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
				@RowEnd = @RowStart + @PageSize - 1

		SELECT
			IBCUserName,
			UserName,
			RegisteredDate,
			Deposit,
			Withdrawal,
			BankingFee,
			Bonus,
			Turnover,
			Winlost
		FROM
		(
			SELECT
				mi.IBCUserName,
				mi.UserName,
				mi.RegisteredDate,
				ROW_NUMBER() OVER (ORDER BY mi.UserName) AS RowNum,
				r.Deposit,
				r.Withdrawal,
				r.BankingFee,
				r.Bonus,
				r.Turnover,
				r.Winloss AS Winlost
			FROM dbo.MemberInfo mi WITH (NOLOCK)
				INNER JOIN #Result r WITH (NOLOCK) ON mi.IBCCustId = r.IBCCustId
			WHERE mi.AffId = @AffId
		) AS result
		WHERE RowNum BETWEEN @RowStart AND @RowEnd

		DROP TABLE #Result
	END
END
GO