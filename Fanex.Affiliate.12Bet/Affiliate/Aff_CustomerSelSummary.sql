ALTER PROCEDURE [dbo].[Aff_CustomerSelSummary] 
	@AffID INT
	,@MonthDate SMALLDATETIME
	,@TotalQualifiedMembers INT OUTPUT
	,@TotalTurnoverForMonth MONEY OUTPUT
	,@TotalActivePlayer INT OUTPUT
	,@TotalPlayerDepUp INT OUTPUT
	,@NewSignUpDep INT OUTPUT
	,@TotalDeposit MONEY OUTPUT
	,@TotalDepositUp MONEY OUTPUT
	,@TotalTurnover MONEY OUTPUT
	,@BalBroughtForward MONEY OUTPUT
AS
/*
	Created: 200900907@VietHoang
	Task : 
	DB: DB052.Affiliate_12BET
	Revisions:
		- 20100520@Johnny: apply StatusID in bettrans table
		- 20101228@Henry: change bettype to new range
		- 20140403@Bobby:  exclude Keno product & other sports

	Param's Explanation:
		• @AffID : Affiliate custid
		• @TotalQualifiedMembers: Total of active members that have turnover for specific month > = 100 USD
		• @TotalTurnoverForMonth: Total of turnover for all members under this Affiliate  
		• @MonthDate : Date search(format:first day of the month).
		• @TotalActivePlayer : Get Active player in Month
		• @TotalPlayerDepUp int OUTPUT,--Get Active player up to now
		• @NewSignUpDep : Get new signups of the month
		• @TotalDeposit : total deposit money for month search
		• @TotalDepositUp money OUTPUT,--total deposit money up to now
		• @TotalTurnover money OUTPUT,--total turnover money up to now		
		• @BalBroughtForward : Money is transferred by monthly task and is approved by affadmin		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentDate SMALLDATETIME
		,@PreviousDate SMALLDATETIME
		,@MaxDateAffBettrans SMALLDATETIME

	SELECT @CurrentDate = convert(VARCHAR(10), CURRENT_TIMESTAMP, 120)
		,@PreviousDate = dateadd(d, - 1, @CurrentDate)

	SELECT @MaxDateAffBettrans = dateadd(d, 1, max(Convert(VARCHAR(10), CompletedDate, 120)))
	FROM Afftrans WITH (NOLOCK)
	WHERE TransType = 201

	IF @MaxDateAffBettrans IS NULL
		SET @MaxDateAffBettrans = dateadd(mm, DATEDIFF(m, 0, CURRENT_TIMESTAMP), 0)

	--Table store all player in downline  
	DECLARE @TblStatistics AS TABLE (
		IbcCustID INT
		,Turnover MONEY
		,Deposit MONEY
		,MonthDate SMALLDATETIME
		)

	--Get data for current date  
	INSERT INTO @TblStatistics
	SELECT m.IbcCustID
		,isnull(sum(CASE 
					WHEN bettype <= 999
						AND StatusID NOT IN (101, 102, 103, 121) THEN stake * e.Actualrate2
					ELSE 0
					END), 0) AS Turnover
		,isnull(sum(CASE bettype
					WHEN 22001 THEN (winlost - actual_stake) * e.Actualrate2
					ELSE 0
					END), 0) AS Deposit
		,convert(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	FROM MemberInfo m WITH (NOLOCK)
		INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK)
		ON m.IbcCustid = b.CustID
		INNER JOIN Exchange_current e WITH (NOLOCK)
		ON m.currency = e.exchangeid
	WHERE m.AffID = @AffID
		AND b.winlostdate = @CurrentDate
		AND m.IsRemoved = 0
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
	GROUP BY m.IbcCustID

	--Get data for the date before yesterday  
	INSERT INTO @TblStatistics
	SELECT m.IbcCustID
		,isnull(sum(Turnover * AffExRate), 0) AS Turnover
		,isnull(sum(Deposit * AffExRate), 0) AS Deposit
		,dateadd(mm, DATEDIFF(m, 0, d.winlostdate), 0)
	FROM MemberInfo m WITH (NOLOCK)
		INNER JOIN MemberDaily d WITH (NOLOCK)
		ON m.IbcCustID = d.IbcCustID
	WHERE m.AffID = @AffID
		AND d.winlostdate <= @PreviousDate
		AND (
			Deposit > 0
			OR TurnOver > 0
			)
	GROUP BY m.IbcCustID
		,dateadd(mm, DATEDIFF(m, 0, d.winlostdate), 0)

	--Assign value to output data  
	--Active players for month search  
	SELECT @TotalActivePlayer = count(DISTINCT IbcCustID)
		,@TotalTurnoverForMonth = sum(isnull(Turnover, 0))
		,@TotalDeposit = sum(isnull(Deposit, 0))
	FROM @TblStatistics
	WHERE DATEDIFF(m, MonthDate, @MonthDate) = 0
		AND (
			turnover > 0
			OR deposit > 0
			) --Because there is still have turnover=0 and deposit=0 in bettrans

	--Get Active player in all date  
	SELECT @TotalPlayerDepUp = count(DISTINCT IbcCustID)
		,@TotalTurnover = sum(Turnover)
		,@TotalDepositUp = sum(Deposit)
	FROM @TblStatistics
	WHERE turnover > 0
		OR deposit > 0 --Because there is still have turnover=0 and deposit=0 in bettrans

	SELECT @NewSignUpDep = count(DISTINCT m.IbcCustID)
	FROM @TblStatistics p
		INNER JOIN MemberInfo m WITH (NOLOCK)
		ON m.IbcCustID = p.IbcCustID
	WHERE m.AffID = @AffID
		AND Deposit > 0
		AND datediff(mm, m.CreatedDate, @MonthDate) = 0

	SELECT @TotalQualifiedMembers = count(1)
	FROM (
		SELECT DISTINCT IbcCustID
		FROM @TblStatistics
		WHERE datediff(m, MonthDate, @MonthDate) = 0
		GROUP BY IbcCustID
		HAVING sum(Turnover) >= 100
		) a

	SELECT @BalBroughtForward = [dbo].[Aff_GetAffBalance](@AffID)

	--Get List tier commission
	DECLARE @GroupId INT

	SELECT @GroupId = GroupId
	FROM AffInfo wiith(NOLOCK)
	WHERE AffId = @AffId

	EXEC Aff_CommGroupSelDetail @GroupId = @GroupId
END
GO

GRANT EXECUTE ON [dbo].[Aff_CustomerSelSummary] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_CustomerSelSummary] TO [bodbDownlineNetView]
GO

GRANT EXECUTE ON [dbo].[Aff_CustomerSelSummary] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelSummary] TO [VNTeam]
