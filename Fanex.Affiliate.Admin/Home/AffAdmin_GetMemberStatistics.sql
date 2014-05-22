ALTER PROCEDURE [dbo].[AffAdmin_GetMemberStatistics] 
	@UserId INT = 0
	,@AffType TINYINT = 0
	,@DepositAll MONEY = 0 OUTPUT
	,@DepositMonth MONEY = 0 OUTPUT
	,@PSPFeeAll MONEY = 0 OUTPUT
	,@PSPFeeMonth MONEY = 0 OUTPUT
	,@WinlostAll MONEY = 0 OUTPUT
	,@WinlostMonth MONEY = 0 OUTPUT
	,@BonusAll MONEY = 0 OUTPUT
	,@BonusMonth MONEY = 0 OUTPUT
	,@AdjustmentAll MONEY = 0 OUTPUT
	,@AdjustmentMonth MONEY = 0 OUTPUT
	,@NetWinlostAll MONEY = 0 OUTPUT
	,@NetWinlostMonth MONEY = 0 OUTPUT
	,@TurnoverAll MONEY = 0 OUTPUT
	,@TurnoverMonth MONEY = 0 OUTPUT
	,@WithdrawalAll MONEY = 0 OUTPUT
	,@WithdrawalMonth MONEY = 0 OUTPUT
	,@TestLevel TINYINT = 0
AS
/*Created: 20131002@Johnny
Task : Gather overview statistic of member information
DB: DB052.Affiliate_AoncashUAT  
  
Revisions:  
 - 20131002@Johnny: Apply test level
 - 20131007@Johnny: Get turnover and withdrawal instead of PSP fee
Param's Explanation:  
    - @TestLevel: 0: real acc; 1: csd test; 2: QC Test
    
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxWinLostDateAffComm SMALLDATETIME
		,@NextMaxWinlostDate SMALLDATETIME
		,@CurrentDate SMALLDATETIME
	DECLARE @tmpCurrency TABLE (
		CurrencyID INT
		,ExRate FLOAT
		)

	SELECT @MaxWinLostDateAffComm = max(winlostdate)
	FROM AffCommission WITH (NOLOCK)

	INSERT INTO @tmpCurrency
	SELECT AttributeID
		,0 AS ExRate
	FROM dbo.Aff_f_GetCurrencybyUser(@userID, 1)

	IF @MaxWinLostDateAffComm IS NULL
	BEGIN
		SELECT @NextMaxWinlostDate = cast((
					SELECT TOP (1) SValue
					FROM SystemSettings(NOLOCK)
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
	SELECT sum(isnull(MemberDeposit, 0)) AS deposit
		,sum((isnull(MemberWinlost, 0))) AS winlost
		,sum(isnull(MemberBonus, 0)) AS bonus
		,sum(isnull(MemberPSP, 0)) AS psp
		,sum(isnull(MemberAdjustment, 0)) AS Adjustment
		,sum(isnull(MemberTurnover, 0)) AS Turnover
		,sum(isnull(MemberWithdrawal, 0)) AS Withdrawal
		,@MaxWinLostDateAffComm AS winlostdate
	FROM AffCommission ac WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK)
		ON ac.AffId = ai.AffId
		INNER JOIN @tmpCurrency t
		ON ai.Currency = t.CurrencyID
	WHERE (
			@AffType = 0
			OR ai.AffType = @AffType
			)
		AND ProductID > 0
		AND winlostdate < @NextMaxWinlostDate
		AND isnull(ai.TestLevel, 0) <= @TestLevel
	
	UNION ALL
	SELECT sum(isnull(MemDeposit, 0) * SysExRate) AS deposit
		,sum((isnull(MemWinlost, 0)) * SysExRate) AS winlost
		,sum(isnull(MemBonus, 0) * SysExRate) AS bonus
		,sum(isnull(MemPSP, 0) * SysExRate) AS psp
		,sum(isnull(MemAdjustment, 0) * SysExRate) AS Adjustment
		,sum(isnull(MemTurnover, 0) * SysExRate) AS Turnover
		,sum(isnull(MemWithdrawal, 0) * SysExRate) AS Withdrawal
		,dateadd(mm, DATEDIFF(m, 0, md.Winlostdate), 0) AS winlostdate
	FROM AffDaily md WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK)
		ON md.AffId = ai.AffId
		INNER JOIN @tmpCurrency t
		ON ai.Currency = t.CurrencyID
	WHERE (
			@AffType = 0
			OR ai.AffType = @AffType
			)
		AND Winlostdate BETWEEN @NextMaxWinlostDate AND @CurrentDate
		AND isnull(ai.TestLevel, 0) <= @TestLevel
	GROUP BY dateadd(mm, DATEDIFF(m, 0, md.winlostdate), 0)

	SELECT @DepositAll = SUM(isnull(Deposit, 0))
		,@WinlostAll = SUM(isnull(Winlost, 0))
		,@BonusAll = SUM(isnull(Bonus, 0))
		,@PSPFeeAll = SUM(isnull(PSP, 0))
		,@AdjustmentAll = SUM(isnull(Adjustment, 0))
		,@TurnoverAll = SUM(isnull(Turnover, 0))
		,@DepositMonth = SUM(CASE 
				WHEN datediff(m, @CurrentDate, winlostdate) = 0 THEN isnull(Deposit, 0)
				ELSE 0
				END)
		,@WinlostMonth = SUM(CASE 
				WHEN datediff(m, @CurrentDate, winlostdate) = 0 THEN isnull(Winlost, 0)
				ELSE 0
				END)
		,@BonusMonth = SUM(CASE 
				WHEN datediff(m, @CurrentDate, winlostdate) = 0 THEN isnull(Bonus, 0)
				ELSE 0
				END)
		,@PSPFeeMonth = SUM(CASE 
				WHEN datediff(m, @CurrentDate, winlostdate) = 0 THEN isnull(PSP, 0)
				ELSE 0
				END)
		,@AdjustmentMonth = SUM(CASE 
				WHEN datediff(m, @CurrentDate, winlostdate) = 0 THEN isnull(Adjustment, 0)
				ELSE 0
				END)
		,@TurnoverMonth = SUM(CASE 
				WHEN datediff(m, @CurrentDate, winlostdate) = 0 THEN isnull(Turnover, 0)
				ELSE 0
				END)
		,@WithdrawalAll = SUM(isnull(Withdrawal, 0))
		,@WithdrawalMonth = SUM(CASE 
				WHEN datediff(m, @CurrentDate, winlostdate) = 0 THEN isnull(Withdrawal, 0)
				ELSE 0
				END)
	FROM @TblStatistics

	SELECT @NetWinlostAll = isnull(@WinlostAll, 0) + isnull(@BonusAll, 0) + isnull(@AdjustmentAll, 0)
		,@NetWinlostMonth = isnull(@WinlostMonth, 0) + isnull(@BonusMonth, 0) + isnull(@AdjustmentMonth, 0)
END
GO


