/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

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
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @WinlostDate SMALLDATETIME
	SELECT  @WinlostDate = @MonthDate
	
	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = dbo.Aff_f_GetMoveBetsDay()

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

	CREATE TABLE #Data
	(
		IBCCustId	INT,
		Deposit		MONEY,
		Withdrawal	MONEY,
		Turnover	MONEY,
		Winloss		MONEY,
		Bonus		MONEY
	)

	-- Old data
	IF @WinlostDate <= @CutOffDate
	BEGIN
		INSERT INTO #Data
		(
			IBCCustId,
			Deposit,
			Withdrawal,
			Turnover,
			Winloss,
			Bonus
		)
		SELECT
			md.IBCCustId,
			SUM(ISNULL(md.Deposit, 0)	* ISNULL(md.AffExRate, 0))	AS Deposit,
			SUM(ISNULL(md.Withdrawal, 0)* ISNULL(md.AffExRate, 0))	AS Withdrawal,
			SUM(CASE WHEN @ProductId = 0 OR md.SportType = @ProductId THEN
				ISNULL(md.Turnover, 0)	* ISNULL(md.AffExRate, 0)
					ELSE 0 END)										AS Turnover,
			SUM(CASE WHEN @ProductId = 0 OR md.SportType = @ProductId THEN
				ISNULL(md.Winlost, 0)	* ISNULL(md.AffExRate, 0)
					ELSE 0 END)										AS Winloss,
			SUM(ISNULL(md.Bonus, 0)		* ISNULL(md.AffExRate, 0))	AS Bonus
		FROM dbo.MemberDaily md WITH (NOLOCK)
		WHERE AffId = @AffId
			AND md.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.IBCCustId = md.IBCCustId
					AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
			)
		GROUP BY
			md.IBCCustId
	END
	-- New data
	ELSE
	BEGIN
		-- rptMemberDaily
		BEGIN
			INSERT INTO #Data
			(
				IBCCustId,
				Deposit,
				Withdrawal,
				Turnover,
				Winloss,
				Bonus
			)
			SELECT
				md.IBCCustId,
				SUM(ISNULL(Deposit, 0)		* ISNULL(md.AffExRate, 0)) AS Deposit,
				SUM(ISNULL(Withdrawal, 0)	* ISNULL(md.AffExRate, 0)) AS Withdrawal,
				SUM(ISNULL(Turnover, 0)		* ISNULL(md.AffExRate, 0)) AS Turnover,
				SUM(ISNULL(Winloss, 0)		* ISNULL(md.AffExRate, 0)) AS Winloss,
				SUM(ISNULL(Bonus, 0)		* ISNULL(md.AffExRate, 0)) AS Bonus
			FROM dbo.rptMemberDaily md WITH (NOLOCK)
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 0, md.Winlostdate, @MoveBetsDay) f
			WHERE AffId = @AffId
				AND md.WinlostDate = @WinlostDate
				AND (@ProductId = 0 OR md.ProductId < 0 OR md.ProductId = @ProductId)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.IBCCustId = md.IBCCustId
						AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
				)
			GROUP BY
				md.IBCCustId
		END

		-- bettrans
		BEGIN
			DECLARE @AffIds VARCHAR(MAX), @ProductIds VARCHAR(MAX)
			SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId), @ProductIds = CONVERT(VARCHAR(5), @ProductId)

			INSERT INTO #Data
			(
				IBCCustId,
				Deposit,
				Withdrawal,
				Turnover,
				Winloss,
				Bonus
			)
			SELECT
				md.IBCCustId,
				SUM(ISNULL(md.Deposit, 0)	* ISNULL(e.ActualRate2, 0)),
				SUM(ISNULL(md.Withdrawal, 0)* ISNULL(e.ActualRate2, 0)),
				SUM(ISNULL(md.Turnover, 0)	* ISNULL(e.ActualRate2, 0)),
				SUM(ISNULL(md.Winloss, 0)	* ISNULL(e.ActualRate2, 0)),
				SUM(ISNULL(md.Bonus, 0)		* ISNULL(e.ActualRate2, 0))
			FROM dbo.Aff_f_Bettrans_Sel(@AffIds, @WinlostDate, @WinlostDate, @ProductIds) md
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(md.Currency, md.WinlostDate) e
				CROSS APPLY dbo.Aff_f_CheckProduct(md.ProductId, 1, md.Winlostdate, @MoveBetsDay) f
			WHERE (@ProductId = 0 OR md.ProductId < 0 OR md.ProductId = @ProductId)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.IBCCustId = md.IBCCustId
						AND mr.RemovedDate <= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, md.WinlostDate) + 1, 0))
				)
			GROUP BY
				md.IBCCustId
		END
	END

	-- Get Banking Fee
	DECLARE @LastDayOfMonth SMALLDATETIME
	SELECT  @LastDayOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	DECLARE @BankingFee DECIMAL(9,8)
	SELECT  @BankingFee = dsh.DeductedPercentage
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
	WHERE agh.AffId = @AffId AND agh.MonthDate = @LastDayOfMonth
		AND dsh.DeductionID = 12 -- Banking Fee
	
	-- Return data
	BEGIN
		SELECT
			mi.IBCCustId AS CustId,
			mi.UserName,
			mi.IBCUsername,
			SUM(ISNULL(dt.Deposit, 0))		AS Deposit,
			SUM(ISNULL(dt.Withdrawal, 0))	AS Withdrawal,
			SUM(ISNULL(dt.Turnover, 0))		AS Turnover,
			SUM(ISNULL(dt.Winloss, 0))		AS Winlost,
			SUM(ISNULL(dt.Bonus, 0))		AS Bonus,
			SUM((ISNULL(dt.Deposit, 0) + ISNULL(dt.Withdrawal, 0)) * ISNULL(@BankingFee, 0)) AS BankingFee
		FROM #Data dt
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON dt.IBCCustId = mi.IBCCustId
		GROUP BY
			mi.IBCCustId,
			mi.UserName,
			mi.IBCUsername
	END

	DROP TABLE #Data
END
GO