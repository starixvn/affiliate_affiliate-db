/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_SubAffiliate_Commission_Sel]
	@AffId			INT,
	@MonthDate		SMALLDATETIME,
	@BaseCurrency	INT = 0,
	@PageIndex		INT = 1,
	@PageSize		INT = 50,
	@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task:
		User site - Statement History - Sub Affiliate Commission
		Admin site - Customer - Statement History - Sub Affiliate Commission

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @AffCurrency INT
	SELECT  @AffCurrency = dbo.Aff_f_GetSetting('AffCurrency')
	
	DECLARE @SubAffCommRate FLOAT = 0.1 -- 10%

	DECLARE @tblSubAffCommission TABLE (AffId INT, UserName NVARCHAR(50), Commission MONEY, SubAffCommission MONEY)

	-- Calculated months
	IF @MonthDate <= @MaxCommDate
	BEGIN
		INSERT INTO @tblSubAffCommission (AffId, UserName, Commission, SubAffCommission)
		SELECT
			ai.AffId
			,ai.UserName
			,SUM(at.Amount * e.Rate) AS Commission
			,SUM(@SubAffCommRate * at.Amount * e.Rate) AS SubAffCommission
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.AffTrans at WITH (NOLOCK) ON ai.AffId = at.AffId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@MonthDate, @AffCurrency, @BaseCurrency) e
		WHERE ai.ParentAffId = @AffId
			AND at.TransDate = @MonthDate
			AND at.TransType IN (201, 204)
		GROUP BY
			ai.AffId
			,ai.UserName
	END
	ELSE
	BEGIN
		DECLARE @AffIds VARCHAR(MAX)
		SELECT  @AffIds = COALESCE(@AffIds + ',', '') + CONVERT(VARCHAR(20), AffId)
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ParentAffId = @AffId
		
		CREATE TABLE #TempCommission
		(
			MonthDate			SMALLDATETIME,
			AffId				INT,
			GroupId				INT,
			ProductId			INT,
			Deposit				MONEY,
			Withdrawal			MONEY,
			Bonus				MONEY,
			Turnover			MONEY,
			Winloss				MONEY,
			-- Fees
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			BankingFee			MONEY,
			-- Calculation
			GrossWinloss		MONEY,
			NetWinloss			MONEY,
			ActivePlayer		INT,
			QualifiedMember		INT,
			QMTurnover			MONEY,
			CommissionRate		FLOAT,
			Commission			MONEY,
			SubAffCommission	MONEY
		)

		INSERT INTO #TempCommission
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			GrossWinloss,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission,
			SubAffCommission
		)
		EXEC dbo.Aff_Commission_UnCalc
			@AffIds				= @AffIds,
			@FromMonthDate		= @MonthDate,
			@ToMonthDate		= @MonthDate,
			@ProductIds			= '0',
			@BaseCurrency		= @BaseCurrency,
			@IsSumAll			= 0,
			@GetRowTotalOnly	= 1

		INSERT INTO @tblSubAffCommission (AffId, UserName, Commission, SubAffCommission)
		SELECT
			ai.AffId
			,ai.UserName
			,SUM(tc.Commission + tc.SubAffCommission) AS Commission
			,SUM(tc.Commission + tc.SubAffCommission) * @SubAffCommRate AS SubAffCommission
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN #TempCommission tc ON ai.AffId = tc.AffId
		GROUP BY
			ai.AffId
			,ai.UserName

		DROP TABLE #TempCommission
	END

	SELECT @NRows = COUNT(1) FROM @tblSubAffCommission

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1
			,@RowEnd = @RowStart + @PageSize - 1

	-- Return detail
	SELECT AffId, UserName, Commission, SubAffCommission
	FROM (
		SELECT AffId, UserName, Commission, SubAffCommission, ROW_NUMBER() OVER(ORDER BY UserName) AS RowNum
		FROM @tblSubAffCommission
	) r
	WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RowNum

	-- Return total
	SELECT 0 AS AffId, '' AS UserName, SUM(Commission) AS Commission, SUM(SubAffCommission) AS SubAffCommission
	FROM @tblSubAffCommission
END
GO