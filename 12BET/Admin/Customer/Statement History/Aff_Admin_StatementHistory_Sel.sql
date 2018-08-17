/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_StatementHistory_Sel] 
	@AffId		INT,
	@TransType	INT = - 1,
	@FDate		SMALLDATETIME = NULL,
	@TDate		SMALLDATETIME = NULL,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@TotalPages INT = 0 OUTPUT,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Customer - Statement History

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	IF (@FDate IS NOT NULL AND @TDate IS NOT NULL AND @FDate > @TDate) 
		RETURN

	IF @TDate > CURRENT_TIMESTAMP
		SELECT @TDate = CURRENT_TIMESTAMP

	IF @FDate IS NOT NULL
		SET @FDate = dbo.Aff_GetStartDate(@FDate)

	IF @TDate IS NOT NULL
		SET @TDate = dbo.Aff_GetEndDate(@TDate)

	CREATE TABLE #Commision
	(
		TransId		BIGINT,
		MonthDate	SMALLDATETIME,
		TransType	INT,
		Amount		MONEY,
		Status		VARCHAR(10),
		Creator		NVARCHAR(50),
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
		TransId,
		MonthDate,
		TransType,
		Amount,
		Status,
		Creator,
		Description
	)
	SELECT
		at.TransId,
		at.TransDate,
		at.TransType,
		CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END AS Amount,
		CASE WHEN at.TransType = 202 THEN at.Status ELSE 'B/F' END AS Status,
		ISNULL(au.Username, 'System') AS Creator,
		CASE WHEN at.TransType = 202 THEN ap.AdminDesc ELSE at.Description END AS Description
	FROM dbo.AffTrans at WITH (NOLOCK)
		LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID AND at.TransType = 202
		LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON at.Creator = au.custid
	WHERE at.AffId = @AffId
		AND at.TransDate BETWEEN @FDate AND @TDate

	-- Commission for months which are not calculated yet
	BEGIN
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(20), @AffId)

		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		IF @TDate > @MaxCommDate
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= @TDate

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
				TransId,
				MonthDate,
				TransType,
				Amount,
				Status,
				Creator,
				Description
			)
			SELECT
				0 AS TransId,
				MonthDate,
				0 AS TransType,
				Commission AS Amount,
				'Current' AS Status,
				'' AS Creator,
				CASE WHEN MonthDate >= CONVERT(DATE, GETDATE()) THEN 'Current Month Statistics' ELSE 'UnCalculated Month' END AS Description
			FROM #TempCommission
			WHERE ProductId = 0
		END
	END

	-- Return data
	SELECT @NRows = COUNT(1) FROM #Commision

	SELECT @TotalPages = @NRows/@PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart = (@PageIndex - 1) * @PageSize + @PageIndex
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT
		TransId,
		MonthDate,
		TransType,
		Amount,
		Status,
		Creator,
		Description
	FROM
	(
		SELECT
			TransId,
			MonthDate,
			TransType,
			Amount,
			Status,
			Creator,
			Description,
			ROW_NUMBER() OVER(ORDER BY MonthDate DESC) AS Rownum
		FROM #Commision
	) AS result
	WHERE Rownum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #Commision
	DROP TABLE #TempCommission
END
GO