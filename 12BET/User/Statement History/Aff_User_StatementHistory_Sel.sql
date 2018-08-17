/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_StatementHistory_Sel]
	@AffId		INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 50,
	@TotalPages INT = 0 OUTPUT,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task:
		User site - Statement History
		Admin site - Customer - Statement History

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #Commision
	(
		MonthDate	SMALLDATETIME,
		TransType	INT,
		Amount		MONEY,
		Status		VARCHAR(10),
		Description	NVARCHAR(2000)
	)

	CREATE NONCLUSTERED INDEX IX_MonthDate ON #Commision (MonthDate)

	/*
		TransType:
			201: Monthly Commission
			202: Payout (Payment Request)
			203: Adjustment
			204: Marketing fee (shut down, still old data)
	*/

	INSERT INTO #Commision
	(
		MonthDate,
		TransType,
		Amount,
		Status,
		Description
	)
	SELECT
		at.TransDate,
		at.TransType,
		CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END AS Amount,
		CASE WHEN at.TransType = 202 THEN at.Status ELSE 'B/F' END AS Status,
		CASE at.TransType WHEN 202 THEN ap.AffDesc WHEN 203 THEN '' ELSE at.Description END AS Description
	FROM dbo.AffTrans at WITH (NOLOCK)
		LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID AND at.TransType = 202
	WHERE at.AffId = @AffId

	-- Commission for months which are not calculated yet
	BEGIN
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME
		SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
				@tempToDate		= CONVERT(DATE, GETDATE())

		CREATE TABLE #TempCommission
		(
			MonthDate		SMALLDATETIME,
			GroupId			INT,
			AffId			INT,
			ProductId		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			-- Fees
			PlatFormFee		MONEY,
			OperationalFee	MONEY,
			BankingFee		MONEY,
			-- Calculation
			NetWinloss		MONEY,
			ActivePlayer	INT,
			QualifiedMember INT,
			QMTurnover		MONEY,
			CommissionRate	DECIMAL(9,8),
			Commission		MONEY,
			-- for monthdate -- 0: temporary, 1: uncalculated, 2: calculated
			CalculatedType	TINYINT DEFAULT ((2))
		)

		INSERT INTO #TempCommission
		(
			MonthDate,
			GroupId,
			AffId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission
		)
		EXEC dbo.Aff_Commission_UnCalc @AffIds = @AffIds, @FromMonthDate = @tempFromDate, @ToMonthDate = @tempToDate
		
		INSERT INTO #Commision
		(
			MonthDate,
			TransType,
			Amount,
			Status,
			Description
		)
		SELECT
			MonthDate,
			0 AS TransType,
			Commission AS Amount,
			'Current' AS Status,
			CASE WHEN MonthDate >= CONVERT(DATE, GETDATE()) THEN 'Current Month Statistics' ELSE 'UnCalculated Month' END AS Description
		FROM #TempCommission
		WHERE ProductId = 0
	END

	-- Return data
	SELECT @NRows = COUNT(1) FROM #Commision

	SELECT @TotalPages = @NRows/@PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + @PageIndex
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT
		MonthDate,
		TransType,
		Amount,
		Status,
		Description
	FROM
	(
		SELECT
			MonthDate,
			TransType,
			Amount,
			Status,
			Description,
			ROW_NUMBER() OVER(ORDER BY MonthDate DESC) AS Rownum
		FROM #Commision
	) AS result
	WHERE Rownum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #Commision
	DROP TABLE #TempCommission
END
GO