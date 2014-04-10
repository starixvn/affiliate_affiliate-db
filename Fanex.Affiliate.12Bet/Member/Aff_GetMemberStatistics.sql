ALTER PROCEDURE [dbo].[Aff_GetMemberStatistics] 
	@AffType TINYINT = 0
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
AS
/*
Created: @
Task : Get member statistic
DB: DB052.Affiliate_12BET
Original: 
Revisions:
	- 20101228@Henry: change bettype to new range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20140228@Bobby : Apply AffType
	- 20140403@Bobby:  exclude Keno product & other sports

Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxWinLostDateAffComm SMALLDATETIME
		,@NextMaxWinlostDate SMALLDATETIME
	DECLARE @CurrentDate SMALLDATETIME
		,@PreviousDate SMALLDATETIME

	SELECT @MaxWinLostDateAffComm = max(winlostdate)
	FROM AffCommission WITH (NOLOCK)

	SELECT @NextMaxWinlostDate = dateadd(d, 1, @MaxWinLostDateAffComm)
		,@CurrentDate = convert(VARCHAR(10), current_timestamp, 120)
		,@PreviousDate = dateadd(d, - 1, @CurrentDate)

	DECLARE @TblStatistics AS TABLE (
		deposit MONEY
		,winlost MONEY
		,bonus MONEY
		,psp MONEY
		,Adjustment MONEY
		,WinlostDate SMALLDATETIME
		)

	INSERT INTO @TblStatistics (
		deposit
		,winlost
		,bonus
		,psp
		,Adjustment
		,winlostdate
		)
	SELECT sum(isnull(MemberDeposit, 0)) AS deposit
		,sum((isnull(MemberWinlost, 0))) AS winlost
		,sum(isnull(MemberBonus, 0)) AS bonus
		,sum(isnull(MemberPSP, 0)) AS psp
		,sum(isnull(MemberAdjustment, 0)) AS Adjustment
		,@MaxWinLostDateAffComm AS winlostdate
	FROM AffCommission ac WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK)
		ON ac.AffId = ai.AffId
	--and ai.AffType = @AffType
		INNER JOIN dbo.AffType at WITH (NOLOCK)
		ON ai.AffType = at.TypeId
	WHERE ai.AffID > 0
		AND SportID > 0
		AND winlostdate < @MaxWinLostDateAffComm
	
	UNION ALL
	SELECT sum(isnull(MemDeposit, 0) * ExRate2) AS deposit
		,sum((isnull(MemWinlost, 0)) * ExRate2) AS winlost
		,sum(isnull(MemBonus, 0) * ExRate2) AS bonus
		,sum(isnull(MemPSP, 0) * ExRate2) AS psp
		,sum(isnull(MemAdjustment, 0) * ExRate2) AS Adjustment
		,dateadd(mm, DATEDIFF(m, 0, md.Winlostdate), 0) AS winlostdate
	FROM AffDaily md WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK)
		ON md.AffId = ai.AffId
	--and ai.AffType = @AffType
		INNER JOIN dbo.AffType at WITH (NOLOCK)
		ON ai.AffType = at.TypeId
	WHERE Winlostdate BETWEEN @NextMaxWinlostDate AND @PreviousDate
	GROUP BY dateadd(mm, DATEDIFF(m, 0, md.winlostdate), 0)
	
	UNION ALL
	SELECT sum(CASE 
				WHEN bettype = 22001 THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0)) * m.ActualRate2
				ELSE 0
				END) AS Deposit
		,sum(CASE 
				WHEN BetType <= 999  THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0) + isnull(playercomm, 0)) * m.ActualRate2
				ELSE 0
				END) AS Winlost
		,sum(CASE 
				WHEN bettype = 22004 THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0)) * m.ActualRate2
				ELSE 0
				END) AS Bonus
		,sum(CASE 
				WHEN bettype = 22001 THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0)) * m.ActualRate2
				ELSE 0
				END) * m.DepositPercent + abs(- sum(CASE 
					WHEN bettype IN (22002, 22003) THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0)) * m.ActualRate2
					ELSE 0
					END)) * m.WithdrawalPercent AS psp
		,sum(CASE 
				WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0)) * m.ActualRate2
				ELSE 0
				END) AS Adjustment
		,@CurrentDate AS winlostdate
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN (
		SELECT m.IBCCustID
			,m.Currency
			,ActualRate2
			,e.DepositPercent
			,e.WithdrawalPercent
		FROM MemberInfo m WITH (NOLOCK)
			INNER JOIN Exchange_Current e WITH (NOLOCK)
			ON e.ExchangeID = m.Currency
			INNER JOIN AffInfo ai WITH (NOLOCK)
			ON m.AffId = ai.AffId
		--and ai.AffType = @AffType
			INNER JOIN dbo.AffType at WITH (NOLOCK)
			ON ai.AffType = at.TypeId
		WHERE m.IsRemoved = 0
		) m
		ON b.CustId = m.IBCCustID
	WHERE b.winlostdate = @CurrentDate
		AND ruben = 1
		AND (
			b.bettype <= 999
			OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
			) --get SB only
		AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
		AND b.bettype NOT IN (1000) --games
		AND b.bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
		AND b.bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
		AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno  
				--and bettype not in (31,32,33,41,42,43)   
		AND b.StatusID NOT IN (101, 102, 103, 121, 1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
	GROUP BY m.DepositPercent
		,m.WithdrawalPercent

	SELECT @DepositAll = SUM(isnull(Deposit, 0))
		,@WinlostAll = SUM(isnull(Winlost, 0))
		,@BonusAll = SUM(isnull(Bonus, 0))
		,@PSPFeeAll = SUM(isnull(PSP, 0))
		,@AdjustmentAll = SUM(isnull(Adjustment, 0))
		,@DepositMonth = SUM(CASE 
				WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Deposit, 0)
				ELSE 0
				END)
		,@WinlostMonth = SUM(CASE 
				WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Winlost, 0)
				ELSE 0
				END)
		,@BonusMonth = SUM(CASE 
				WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Bonus, 0)
				ELSE 0
				END)
		,@PSPFeeMonth = SUM(CASE 
				WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(PSP, 0)
				ELSE 0
				END)
		,@AdjustmentMonth = SUM(CASE 
				WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Adjustment, 0)
				ELSE 0
				END)
	FROM @TblStatistics

	SELECT @NetWinlostAll = isnull(@WinlostAll, 0) + isnull(@BonusAll, 0) + isnull(@AdjustmentAll, 0)
		,@NetWinlostMonth = isnull(@WinlostMonth, 0) + isnull(@BonusMonth, 0) + isnull(@AdjustmentMonth, 0)
END
GO

GRANT EXECUTE ON [dbo].[Aff_GetMemberStatistics] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_GetMemberStatistics] TO [vnteam]
