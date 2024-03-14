/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_SubAffiliate_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Sub-Affiliate Details

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Include P2P Earning into Monthly Earning & Treat TO, WL = 0 for P2P Products [RedmineID: #157958]
		- 20210916@Percy: Change WL to GGR [RedmineID: #161540]
		- 20220307@Malcolm: Revenue Share Calculation Enhancement [RedmineId: #167335]
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @BeginOfMonth))

	-- Total Turnover, Winloss, Commission
	BEGIN
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

		DECLARE @MaxCommDate SMALLDATETIME, @AffIds VARCHAR(MAX)
		
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120)
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName = 'AFF_CommissionDate'
		
		SELECT  @AffIds = COALESCE(@AffIds + ',', '') + CONVERT(VARCHAR(20), AffId)
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ParentAffId = @AffId
			AND Status = 'Approved'
			AND IsClosed = 0
			AND ISNULL(IsSuspended, 0) = 0
			AND ApprovedDate < DATEADD(DAY, 1, @EndOfMonth)

		IF @BeginOfMonth > @MaxCommDate
		BEGIN
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
				@FromMonthDate		= @BeginOfMonth,
				@ToMonthDate		= @BeginOfMonth,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END
		ELSE
		BEGIN
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
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds,
				@FromMonthDate		= @BeginOfMonth,
				@ToMonthDate		= @BeginOfMonth,
				@ProductIds			= '0',
				@BaseCurrency		= @BaseCurrency,
				@IsSumAll			= 1,
				@GetRowTotalOnly	= 1
		END
	END

	-- Return data
	BEGIN
		SELECT
			ai.AffId
			,ai.UserName
			,ai.FirstName
			,ai.LastName
			,ai.ApprovedDate
			,ai.IsSuspended
			,ai.SuspendedDate
			,c.Turnover
			,c.GGR
			,c.Commission
			,c.ActivePlayer
		FROM dbo.AffInfo ai WITH (NOLOCK)
			OUTER APPLY (
				SELECT
					SUM(c.Turnover) AS Turnover
					,SUM(-c.Winloss + c.Revenue) AS GGR
					,SUM(c.Commission + c.StraightCommission + c.SubAffCommission) AS Commission
					,SUM(c.ActivePlayer) AS ActivePlayer
				FROM #TempCommission c
				WHERE ai.AffId = c.AffId
					AND ISNULL(ai.IsSuspended, 0) = 0
			) c
		WHERE ai.ParentAffId = @AffId
			AND ai.Status = 'Approved'
			AND ai.IsClosed = 0
			AND ai.ApprovedDate < DATEADD(DAY, 1, @EndOfMonth)
		ORDER BY
			ai.IsSuspended
			,ai.UserName
	END

	DROP TABLE #TempCommission
END
GO