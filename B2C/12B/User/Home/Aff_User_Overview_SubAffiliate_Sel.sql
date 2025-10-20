/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Overview_SubAffiliate_Sel]
	@AffId			INT
	,@FromDate		SMALLDATETIME
	,@ToDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@IsGetMonthly  BIT = 1
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Sub-Affiliate Details

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20241226@Sally: Apply QM Turnover [RedmineID: #212201]
		- 20250918@Lewis: Get CPAAmount data [RedmineID: #238519]

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
			NetTurnover			MONEY,
			ActivePlayer		INT,
			QualifiedMember     INT,
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
				NetTurnover,
				ActivePlayer,
				QualifiedMember,
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
				NetTurnover,
				ActivePlayer,
				QualifiedMember,
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
			,c.QualifiedMember
		FROM dbo.AffInfo ai WITH (NOLOCK)
			OUTER APPLY (
				SELECT
					SUM(c.Turnover) AS Turnover
					,SUM(-c.Winloss + c.Revenue) AS GGR
					,SUM(c.Commission + c.StraightCommission + c.SubAffCommission) AS Commission
					,SUM(c.ActivePlayer) AS ActivePlayer
					,SUM(c.QualifiedMember) AS QualifiedMember
				FROM #TempCommission c
				WHERE ai.AffId = c.AffId
					AND ISNULL(ai.IsSuspended, 0) = 0
			) c
		WHERE ai.ParentAffId = @AffId
			AND ai.Status = 'Approved'
			AND ai.IsClosed = 0
			AND ai.ApprovedDate < DATEADD(DAY, 1, @EndOfMonth)
		ORDER BY
			ai.IsSuspended ASC
			,ai.UserName ASC
	END

	DROP TABLE #TempCommission
END
GO