ALTER PROCEDURE [dbo].[AffAdmin_GetMemberStatistics] 
	@LicenseeID			INT
	,@UserId 			INT 	= 0
	,@AffType 			TINYINT = 0
	,@DepositAll 		MONEY 	= 0 OUTPUT
	,@DepositMonth 		MONEY 	= 0 OUTPUT
	,@PSPFeeAll 		MONEY 	= 0 OUTPUT
	,@PSPFeeMonth 		MONEY 	= 0 OUTPUT
	,@WinlostAll 		MONEY 	= 0 OUTPUT
	,@WinlostMonth 		MONEY 	= 0 OUTPUT
	,@BonusAll 			MONEY 	= 0 OUTPUT
	,@BonusMonth 		MONEY 	= 0 OUTPUT
	,@AdjustmentAll 	MONEY 	= 0 OUTPUT
	,@AdjustmentMonth 	MONEY 	= 0 OUTPUT
	,@NetWinlostAll 	MONEY 	= 0 OUTPUT
	,@NetWinlostMonth 	MONEY 	= 0 OUTPUT
	,@TurnoverAll 		MONEY 	= 0 OUTPUT
	,@TurnoverMonth 	MONEY 	= 0 OUTPUT
	,@WithdrawalAll 	MONEY 	= 0 OUTPUT
	,@WithdrawalMonth 	MONEY 	= 0 OUTPUT
	,@TestLevel 		TINYINT = 0
AS
/*Created: 20131002@Johnny
Task : Gather overview statistic of member information
DB: DB052.Affiliate_AoncashUAT  
  
Revisions:  
	- 20131002@Johnny: Apply test level
	- 20131007@Johnny: Get turnover and withdrawal instead of PSP fee
	- 20140819@Bobby: Apply SQL style scope
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	
Param's Explanation:  
    - @TestLevel: 0: real acc; 1: csd test; 2: QC Test
    
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxWinLostDateAffComm 	SMALLDATETIME
		,@NextMaxWinlostDate 		SMALLDATETIME
		,@CurrentDate 				SMALLDATETIME
	DECLARE @tmpCurrency TABLE (
		CurrencyID INT
		,ExRate FLOAT
		)

	SELECT @MaxWinLostDateAffComm = max(winlostdate)
	FROM dbo.AffCommission WITH (NOLOCK)

	INSERT INTO @tmpCurrency
	SELECT AffCurrencyID
		,0 AS ExRate
	FROM dbo.AffAdmin_f_UserCurrency_Select(@userID, @LicenseeID)

	IF @MaxWinLostDateAffComm IS NULL
	BEGIN
		SELECT @NextMaxWinlostDate = cast((
					SELECT TOP (1) SValue
					FROM dbo.SystemSettings WITH(NOLOCK)
					WHERE Type = 'Meta'
						AND SName = 'SystemStartDate'
					) AS SMALLDATETIME)
	END
	ELSE
	BEGIN
		SELECT @NextMaxWinlostDate = dateadd(d, 1, @MaxWinLostDateAffComm)
	END

	SELECT @CurrentDate = getdate()

	DECLARE @TblStatistics AS TABLE (
		deposit MONEY
		,winlost MONEY
		,bonus MONEY
		,psp MONEY
		,Adjustment MONEY
		,Turnover MONEY
		,Withdrawal MONEY
		,WinlostDate SMALLDATETIME
		)

	INSERT INTO @TblStatistics (
		deposit
		,winlost
		,bonus
		,psp
		,Adjustment
		,Turnover
		,Withdrawal
		,winlostdate
		)
	SELECT SUM(ISNULL(MemberDeposit, 0)) AS deposit
		,SUM((ISNULL(MemberWinlost, 0))) AS winlost
		,SUM(ISNULL(MemberBonus, 0)) AS bonus
		,SUM(ISNULL(MemberPSP, 0)) AS psp
		,SUM(ISNULL(MemberAdjustment, 0)) AS Adjustment
		,SUM(ISNULL(MemberTurnover, 0)) AS Turnover
		,SUM(ISNULL(MemberWithdrawal, 0)) AS Withdrawal
		,@MaxWinLostDateAffComm AS winlostdate
	FROM dbo.AffCommission ac WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON ac.AffId = ai.AffId
		INNER JOIN @tmpCurrency t
		ON ai.Currency = t.CurrencyID
	WHERE (
			@AffType = 0
			OR ai.AffType = @AffType
			)
		AND ProductID > 0
		AND winlostdate < @NextMaxWinlostDate
		AND ISNULL(ai.TestLevel, 0) <= @TestLevel
	
	UNION ALL
	SELECT SUM(ISNULL(MemDeposit, 0) * SysExRate) AS deposit
		,SUM((ISNULL(MemWinlost, 0)) * SysExRate) AS winlost
		,SUM(ISNULL(MemBonus, 0) * SysExRate) AS bonus
		,SUM(ISNULL(MemPSP, 0) * SysExRate) AS psp
		,SUM(ISNULL(MemAdjustment, 0) * SysExRate) AS Adjustment
		,SUM(ISNULL(MemTurnover, 0) * SysExRate) AS Turnover
		,SUM(ISNULL(MemWithdrawal, 0) * SysExRate) AS Withdrawal
		,dateadd(mm, DATEDIFF(m, 0, md.Winlostdate), 0) AS winlostdate
	FROM dbo.AffDaily md WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON md.AffId = ai.AffId
		INNER JOIN @tmpCurrency t
		ON ai.Currency = t.CurrencyID
	WHERE (
			@AffType = 0
			OR ai.AffType = @AffType
			)
		AND Winlostdate BETWEEN @NextMaxWinlostDate AND @CurrentDate
		AND ISNULL(ai.TestLevel, 0) <= @TestLevel
	GROUP BY dateadd(mm, DATEDIFF(m, 0, md.winlostdate), 0)

	SELECT @DepositAll = SUM(ISNULL(Deposit, 0))
		,@WinlostAll = SUM(ISNULL(Winlost, 0))
		,@BonusAll = SUM(ISNULL(Bonus, 0))
		,@PSPFeeAll = SUM(ISNULL(PSP, 0))
		,@AdjustmentAll = SUM(ISNULL(Adjustment, 0))
		,@TurnoverAll = SUM(ISNULL(Turnover, 0))
		,@DepositMonth = SUM(CASE 
				WHEN DATEDIFF(m, @CurrentDate, winlostdate) = 0 THEN ISNULL(Deposit, 0)
				ELSE 0
				END)
		,@WinlostMonth = SUM(CASE 
				WHEN DATEDIFF(m, @CurrentDate, winlostdate) = 0 THEN ISNULL(Winlost, 0)
				ELSE 0
				END)
		,@BonusMonth = SUM(CASE 
				WHEN DATEDIFF(m, @CurrentDate, winlostdate) = 0 THEN ISNULL(Bonus, 0)
				ELSE 0
				END)
		,@PSPFeeMonth = SUM(CASE 
				WHEN DATEDIFF(m, @CurrentDate, winlostdate) = 0 THEN ISNULL(PSP, 0)
				ELSE 0
				END)
		,@AdjustmentMonth = SUM(CASE 
				WHEN DATEDIFF(m, @CurrentDate, winlostdate) = 0 THEN ISNULL(Adjustment, 0)
				ELSE 0
				END)
		,@TurnoverMonth = SUM(CASE 
				WHEN DATEDIFF(m, @CurrentDate, winlostdate) = 0 THEN ISNULL(Turnover, 0)
				ELSE 0
				END)
		,@WithdrawalAll = SUM(ISNULL(Withdrawal, 0))
		,@WithdrawalMonth = SUM(CASE 
				WHEN DATEDIFF(m, @CurrentDate, winlostdate) = 0 THEN ISNULL(Withdrawal, 0)
				ELSE 0
				END)
	FROM @TblStatistics

	SELECT @NetWinlostAll = ISNULL(@WinlostAll, 0) + ISNULL(@BonusAll, 0) + ISNULL(@AdjustmentAll, 0)
		,@NetWinlostMonth = ISNULL(@WinlostMonth, 0) + ISNULL(@BonusMonth, 0) + ISNULL(@AdjustmentMonth, 0)
END
GO


