/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_PlayersDetail_Sel]
	@AffId		INT,
	@Sporttype	INT = 0,
	@MonthDate	SMALLDATETIME = NULL,
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

	DECLARE @ProductId INT
	SELECT  @ProductId = ISNULL(@Sporttype, 0)

	IF @MonthDate IS NULL
	BEGIN
		SELECT @FromDate = '2009-10-01', @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	END
	ELSE
	BEGIN
		SELECT	@FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0), -- Begin Month
				@ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0)) -- End Month
	END

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	DECLARE @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME

	CREATE TABLE #AffData
	(
		IBCCustId	INT,
		Deposit		MONEY,
		Withdrawal	MONEY,
		BankingFee	MONEY,
		Bonus		MONEY,
		Turnover	MONEY,
		Winloss		MONEY
	)

	CREATE CLUSTERED INDEX CIX_IBCCustId ON #AffData (IBCCustId)

	-- MemberDaily
	IF @FromDate < @CutOffDate
	BEGIN
		SELECT @tmpFromDate = @FromDate
		SELECT @tmpToDate = CASE WHEN @ToDate >= @CutOffDate THEN @CutOffDate ELSE @ToDate END

		INSERT INTO #AffData
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
			SUM(ISNULL(md.PSP, 0)			* ISNULL(md.AffExRate, 0)) AS BankingFee,
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
	IF @ToDate >= @CutOffDate
	BEGIN
		SELECT @tmpFromDate = CASE WHEN @FromDate < @CutOffDate THEN @CutOffDate ELSE @ToDate END
		SELECT @tmpToDate = @ToDate

		INSERT INTO #AffData
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
		GROUP BY
			md.IBCCustId
	END

	-- bettrans
	IF @ToDate > @MoveBetsDay
	BEGIN
		DECLARE @tmpDate SMALLDATETIME
		SELECT  @tmpDate = CASE WHEN @FromDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromDate END

		INSERT INTO #AffData
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
		FROM OPENQUERY(DBEXT, 'SELECT WinlostDate,IBCCustId,ProductId,Currency,Deposit,Withdrawal,Bonus,Turnover,Winloss
										FROM bodb02.dbo.Aff_f_Bettrans_Sel()') md
			CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
			CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.WinlostDate, @MoveBetsDay) f
			CROSS APPLY dbo.Aff_f_GetSettingAll(@AffId, 0, md.WinlostDate) s
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON md.IBCCustId = mi.IBCCustId AND mi.AffId = @AffId
		WHERE (@ProductId = 0 OR md.ProductId = @ProductId OR md.ProductId < 0)
			AND md.WinlostDate BETWEEN @tmpDate AND @ToDate
		GROUP BY
			md.IBCCustId
	END

	-- Return data
	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
			@RowEnd = @RowStart + @PageSize - 1

	SELECT
		IBCUserName,
		UserName,
		RegisteredDate,
		Deposit,
		Withdrawal,
		PSP,
		Bonus,
		Adjustment,
		Turnover,
		Winlost
	FROM
	(
		SELECT
			mi.IBCUserName,
			mi.UserName,
			mi.RegisteredDate,
			DENSE_RANK() OVER (ORDER BY mi.UserName ASC) AS RowNum,
			SUM(ISNULL(ad.Deposit, 0)) AS Deposit,
			SUM(ISNULL(ad.Withdrawal, 0)) AS Withdrawal,
			SUM(ISNULL(ad.BankingFee, 0)) AS PSP,
			SUM(ISNULL(ad.Bonus, 0)) AS Bonus,
			0 AS Adjustment, -- will remove later
			SUM(ISNULL(ad.Turnover, 0)) AS Turnover,
			SUM(ISNULL(ad.Winloss, 0)) AS Winlost
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN #AffData ad WITH (NOLOCK) ON mi.IBCCustId = ad.IBCCustId
		WHERE mi.AffId = @AffId
		GROUP BY
			mi.IBCUserName,
			mi.UserName,
			mi.RegisteredDate
	) AS result
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #AffData
END
GO