/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_SubAffiliate_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Sub-Affiliate Details

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

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
			-- Fees
			PlatFormFee			MONEY,
			OperationalFee		MONEY,
			DepositFee			MONEY,
			WithdrawalFee		MONEY,
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
			AND ApprovedDate < @ToNextMonth

		IF @FromBeginMonth > @MaxCommDate
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
				PlatFormFee,
				OperationalFee,
				DepositFee,
				WithdrawalFee,
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
				@FromMonthDate		= @FromBeginMonth,
				@ToMonthDate		= @FromBeginMonth,
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
				PlatFormFee,
				OperationalFee,
				DepositFee,
				WithdrawalFee,
				GrossWinloss,
				NetWinloss,
				ActivePlayer,
				QualifiedMember,
				QMTurnOver,
				CommissionRate,
				Commission,
				SubAffCommission
			)
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= @AffIds,
				@FromMonthDate		= @FromBeginMonth,
				@ToMonthDate		= @FromBeginMonth,
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
			,c.Winloss
			,c.Commission
			,c.ActivePlayer
		FROM dbo.AffInfo ai WITH (NOLOCK)
			OUTER APPLY (
				SELECT
					SUM(c.Turnover) AS Turnover
					,SUM(c.Winloss) AS Winloss
					,SUM(c.Commission + c.SubAffCommission) AS Commission
					,SUM(c.ActivePlayer) AS ActivePlayer
				FROM #TempCommission c
				WHERE ai.AffId = c.AffId
					AND ISNULL(ai.IsSuspended, 0) = 0
			) c
		WHERE ai.ParentAffId = @AffId
			AND ai.Status = 'Approved'
			AND ai.IsClosed = 0
			AND ai.ApprovedDate < @ToNextMonth
		ORDER BY
			ai.IsSuspended
			,ai.UserName
	END

	DROP TABLE #TempCommission
END
GO