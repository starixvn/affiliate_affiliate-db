ALTER PROCEDURE [dbo].[Aff_CustomerSelSummary]
	@AffID int,
	@MonthDate smalldatetime,
	@TotalQualifiedMembers int OUTPUT,
	@TotalTurnoverForMonth money OUTPUT,
	@TotalActivePlayer int OUTPUT,
	@TotalPlayerDepUp int OUTPUT,
	@NewSignUpDep int OUTPUT,
	@TotalDeposit money OUTPUT,
	@TotalDepositUp money OUTPUT,
	@TotalTurnover money OUTPUT,	
	@BalBroughtForward money OUTPUT	
AS
/*
	Created: 200900907@VietHoang
	Task : 
	DB: DB052.Affiliate_12BET
	Revisions:
		- 20100520@Johnny: apply StatusID in bettrans table
		- 20101228@Henry: change bettype to new range
		- 20120606@Peter : Exclude waiting tickets
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
 SET NOCOUNT ON  
declare @CurrentDate smalldatetime, @PreviousDate smalldatetime, @MaxDateAffBettrans smalldatetime  
   
select @CurrentDate=convert(varchar(10),CURRENT_TIMESTAMP,120),  
		@PreviousDate=dateadd(d, -1, @CurrentDate)  
  
select @MaxDateAffBettrans = dateadd(d, 1, max(Convert(varchar(10),CompletedDate,120)))  
from Afftrans with(nolock)   
where TransType = 201  
  
IF @MaxDateAffBettrans is null 
	SET @MaxDateAffBettrans = dateadd(mm, DATEDIFF(m,0,CURRENT_TIMESTAMP), 0)

--Table store all player in downline  
Declare @TblStatistics as table(IbcCustID int, Turnover money, Deposit money, MonthDate smalldatetime)  
  
--Get data for current date  
INSERT INTO @TblStatistics  
SELECT   
	m.IbcCustID,   
	isnull(sum(case when bettype < 99 and StatusID not in (101, 102, 103, 121,1) then stake * e.Actualrate2 else 0 end),0) as Turnover,  
	isnull(sum(case bettype when 22001 then (winlost-actual_stake)* e.Actualrate2 else 0 end),0) as Deposit,  	
	convert(varchar(10),CURRENT_TIMESTAMP,120)  
FROM MemberInfo m with (nolock)  
	INNER JOIN bodb02.dbo.bettrans b with (nolock) on m.IbcCustid = b.CustID
	INNER JOIN Exchange_current e with(nolock) on m.currency = e.exchangeid  
WHERE m.AffID = @AffID
	AND b.winlostdate=@CurrentDate  
	and m.IsRemoved=0
	and b.bettype not in (71,72,73,74,75,76,77,78,79) -- exclude Casino
GROUP BY m.IbcCustID  
  
--Get data for the date before yesterday  
INSERT INTO @TblStatistics  
SELECT m.IbcCustID,  
	isnull(sum(Turnover * AffExRate), 0) as Turnover,  
	isnull(sum(Deposit * AffExRate), 0) as Deposit,    
	dateadd(mm, DATEDIFF(m,0,d.winlostdate), 0)  
FROM MemberInfo m with(nolock)  
	INNER JOIN MemberDaily d with(nolock) on m.IbcCustID = d.IbcCustID
WHERE m.AffID = @AffID
	AND d.winlostdate <= @PreviousDate
	AND (Deposit > 0 OR TurnOver > 0)  
GROUP BY m.IbcCustID, dateadd(mm, DATEDIFF(m,0,d.winlostdate), 0)  
  
--Assign value to output data  
--Active players for month search  
SELECT @TotalActivePlayer = count(distinct IbcCustID),  
	@TotalTurnoverForMonth = sum(isnull(Turnover, 0)),  
	@TotalDeposit = sum(isnull(Deposit, 0))  
FROM @TblStatistics  
WHERE DATEDIFF(m, MonthDate, @MonthDate) = 0  
	AND (turnover > 0 or deposit > 0)--Because there is still have turnover=0 and deposit=0 in bettrans
  
--Get Active player in all date  
SELECT @TotalPlayerDepUp = count(distinct IbcCustID),  
	@TotalTurnover = sum(Turnover),  
	@TotalDepositUp = sum(Deposit)  
FROM @TblStatistics  
WHERE turnover > 0 or deposit > 0--Because there is still have turnover=0 and deposit=0 in bettrans
  
SELECT @NewSignUpDep = count(distinct m.IbcCustID)  
FROM @TblStatistics p  
	INNER JOIN MemberInfo m with (nolock) on m.IbcCustID = p.IbcCustID
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
Declare @GroupId int
select @GroupId = GroupId from AffInfo wiith (nolock) where AffId = @AffId
		
Exec Aff_CommGroupSelDetail @GroupId = @GroupId														
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelSummary] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelSummary] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelSummary] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelSummary] TO [VNTeam]