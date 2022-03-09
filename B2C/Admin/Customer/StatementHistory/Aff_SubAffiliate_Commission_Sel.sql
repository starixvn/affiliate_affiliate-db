/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_SubAffiliate_Commission_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 50
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task:
		User site - Statement History - Sub Affiliate Commission
		Admin site - Customer - Statement History - Sub Affiliate Commission

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210506@Percy: Max Sub Affiliate Commission Setting [RedmineID: #153465]
		- 20210714@Percy: Include P2P Earning into Monthly Earning [RedmineID: #157958]
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
			Rebate				MONEY,
			Turnover			MONEY,
			Winloss				MONEY,
			Revenue				MONEY,
			-- Fees
			P2PFee				MONEY,
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			DepositFee			MONEY,
			WithdrawalFee		MONEY,
			-- Calculation
			GrossWinloss		MONEY,
			NetWinloss			MONEY,
			ActivePlayer		INT,
			CommissionRate		FLOAT,
			Commission			MONEY,
			StraightCommission	MONEY,
			SubAffCommission	MONEY,
			IsMultiGroupProduct BIT
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
			Rebate,
			Turnover,
			Winloss,
			Revenue,
			P2PFee,
			PlatFormFee,
			OperationalFee,
			DepositFee,
			WithdrawalFee,
			GrossWinloss,
			NetWinloss,
			ActivePlayer,
			CommissionRate,
			Commission,
			StraightCommission,
			SubAffCommission,
			IsMultiGroupProduct
		)
		EXEC dbo.Aff_Commission_UnCalc
			@AffIds				= @AffIds,
			@FromMonthDate		= @MonthDate,
			@ToMonthDate		= @MonthDate,
			@ProductIds			= '0',
			@BaseCurrency		= @BaseCurrency,
			@SubLevel			= 2,
			@IsSumAll			= 0,
			@GetRowTotalOnly	= 1

		INSERT INTO @tblSubAffCommission (AffId, UserName, Commission, SubAffCommission)
		SELECT
			ai.AffId
			,ai.UserName
			,SUM(tc.Commission + tc.StraightCommission + tc.SubAffCommission) AS Commission
			,SUM(tc.Commission + tc.StraightCommission + tc.SubAffCommission) * @SubAffCommRate AS SubAffCommission
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