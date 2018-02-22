/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_GetMemberStatistics] 
	@AffType			TINYINT = 0
	,@DepositAll		MONEY = 0 OUTPUT
	,@DepositMonth		MONEY = 0 OUTPUT
	,@PSPFeeAll			MONEY = 0 OUTPUT
	,@PSPFeeMonth		MONEY = 0 OUTPUT
	,@WinlostAll		MONEY = 0 OUTPUT
	,@WinlostMonth		MONEY = 0 OUTPUT
	,@BonusAll			MONEY = 0 OUTPUT
	,@BonusMonth		MONEY = 0 OUTPUT
	,@AdjustmentAll		MONEY = 0 OUTPUT
	,@AdjustmentMonth	MONEY = 0 OUTPUT
	,@NetWinlostAll		MONEY = 0 OUTPUT
	,@NetWinlostMonth	MONEY = 0 OUTPUT
AS

/*
	Created:
	Task: Get member statistic
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20101228@Henry: change bettype to new range
		- 20111031@Peter: Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20140228@Bobby: Apply AffType
		- 20140403@Bobby: Exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MaxWinLostDateAffComm SMALLDATETIME, @NextMaxWinlostDate SMALLDATETIME
	DECLARE @CurrentDate SMALLDATETIME, @PreviousDate SMALLDATETIME

	SELECT @MaxWinLostDateAffComm = MAX(winlostdate)
	FROM dbo.AffCommission WITH (NOLOCK)

	SELECT
		@NextMaxWinlostDate = DATEADD(DAY, 1, @MaxWinLostDateAffComm)
		,@CurrentDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
		,@PreviousDate = DATEADD(DAY, - 1, @CurrentDate)

	DECLARE @TblStatistics TABLE
	(
		deposit MONEY
		,winlost MONEY
		,bonus MONEY
		,psp MONEY
		,Adjustment MONEY
		,WinlostDate SMALLDATETIME
	)

	INSERT INTO @TblStatistics
	(
		deposit
		,winlost
		,bonus
		,psp
		,Adjustment
		,winlostdate
	)
	SELECT
		SUM(ISNULL(MemberDeposit, 0)) AS deposit
		,SUM(ISNULL(MemberWinlost, 0)) AS winlost
		,SUM(ISNULL(MemberBonus, 0)) AS bonus
		,SUM(ISNULL(MemberPSP, 0)) AS psp
		,SUM(ISNULL(MemberAdjustment, 0)) AS Adjustment
		,@MaxWinLostDateAffComm AS winlostdate
	FROM dbo.AffCommission ac WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ac.AffId = ai.AffId
		INNER JOIN dbo.AffType at WITH (NOLOCK) ON ai.AffType = at.TypeId
	WHERE ai.AffID > 0
		AND SportID > 0
		AND winlostdate <= @MaxWinLostDateAffComm
	
	UNION ALL
	SELECT
		SUM(ISNULL(MemDeposit, 0) * ExRate2) AS deposit
		,SUM(ISNULL(MemWinlost, 0) * ExRate2) AS winlost
		,SUM(ISNULL(MemBonus, 0) * ExRate2) AS bonus
		,SUM(ISNULL(MemPSP, 0) * ExRate2) AS psp
		,SUM(ISNULL(MemAdjustment, 0) * ExRate2) AS Adjustment
		,DATEADD(mm, DATEDIFF(m, 0, md.Winlostdate), 0) AS winlostdate
	FROM dbo.AffDaily md WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON md.AffId = ai.AffId
		INNER JOIN dbo.AffType at WITH (NOLOCK) ON ai.AffType = at.TypeId
	WHERE Winlostdate BETWEEN @NextMaxWinlostDate AND @PreviousDate
	GROUP BY DATEADD(mm, DATEDIFF(m, 0, md.winlostdate), 0)
	
	UNION ALL
	SELECT sum(CASE 
				WHEN bettype = 22001 THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0)) * m.ActualRate2
				ELSE 0
				END) AS Deposit
		,sum(CASE 
				WHEN (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))  THEN (isnull(winlost, 0) - isnull(abs(actual_stake), 0) + isnull(playercomm, 0)) * m.ActualRate2
				ELSE 0
				END
			*
			CASE
				WHEN bettype = 911 THEN DeductedPercentage
				ELSE 1
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
				,ISNULL(ds.DeductedPercentage, 0) AS DeductedPercentage
			FROM MemberInfo m WITH (NOLOCK)
				INNER JOIN Exchange_Current e WITH (NOLOCK) ON e.ExchangeID = m.Currency
				INNER JOIN AffInfo ai WITH (NOLOCK) ON m.AffId = ai.AffId
				INNER JOIN dbo.AffType at WITH (NOLOCK) ON ai.AffType = at.TypeId
				LEFT JOIN dbo.DeductionSetting ds WITH(NOLOCK) ON ai.GroupID = ds.GroupID AND ds.DeductionID = 9
			WHERE m.IsRemoved = 0
		) m ON b.CustId = m.IBCCustID
	WHERE b.winlostdate = @CurrentDate
		AND ruben = 1
		AND (
			b.bettype <= 999
			OR ( b.bettype BETWEEN 1301 AND 1399)
			OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
			) --get SB only
		AND b.bettype NOT BETWEEN 31 AND 120 -- Not include Casino and Number Game and finance
		AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
		AND b.StatusID NOT IN (101, 102, 103, 121, 1)
	GROUP BY m.DepositPercent
		,m.WithdrawalPercent

	SELECT @DepositAll = SUM(ISNULL(Deposit, 0))
		,@WinlostAll = SUM(ISNULL(Winlost, 0))
		,@BonusAll = SUM(ISNULL(Bonus, 0))
		,@PSPFeeAll = SUM(ISNULL(PSP, 0))
		,@AdjustmentAll = SUM(ISNULL(Adjustment, 0))
		,@DepositMonth = SUM(CASE WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Deposit, 0) ELSE 0 END)
		,@WinlostMonth = SUM(CASE WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Winlost, 0) ELSE 0 END)
		,@BonusMonth = SUM(CASE WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Bonus, 0) ELSE 0 END)
		,@PSPFeeMonth = SUM(CASE WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(PSP, 0) ELSE 0 END)
		,@AdjustmentMonth = SUM(CASE WHEN datediff(mm, @CurrentDate, winlostdate) = 0 THEN isnull(Adjustment, 0) ELSE 0 END)
	FROM @TblStatistics

	SELECT @NetWinlostAll = isnull(@WinlostAll, 0) + isnull(@BonusAll, 0) + isnull(@AdjustmentAll, 0)
		,@NetWinlostMonth = isnull(@WinlostMonth, 0) + isnull(@BonusMonth, 0) + isnull(@AdjustmentMonth, 0)
END
GO