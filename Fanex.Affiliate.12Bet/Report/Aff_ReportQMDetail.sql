 ALTER PROCEDURE [dbo].[Aff_ReportQMDetail]
	@AffID int,
	@Month int,
	@Year int,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT    
AS

/*
Created: 20091213@Peter
Task : Get List of Qualifying members report for one affiliate.
DB: DB052.Affiliate_12BET
Original: 
Revisions:
	- 20110523@Henry: change bettype to new range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120606@Peter : Exclude waiting tickets
Param's Explanation:
	
*/
SET NOCOUNT ON
 
DECLARE @TblResult TABLE(IBCCustId int PRIMARY KEY, SPTurnOver money, HRTurnOver money, CATurnover money, CADeposit money)

DECLARE @MemList TABLE(IBCCustId int, AffExRate float)

insert into @MemList
select m.IBCCustId, e.ActualRate2
From MemberInfo m with (nolock) 
	inner join Exchange_Current e with (nolock) on m.Currency = e.ExchangeId
where m.AffId = @AffId and IsRemoved = 0

--select * from @MemList

Declare @FirstDay smalldatetime,@LastDay smalldatetime,@CurrDate smalldatetime,@SportsBookID int,@HorseRacingID int,@CasinoID int,@SPQMAmount money,@HRQMAmount money,@CAQMAmount money,@CAQMDeposit money

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing'), @CasinoID = dbo.Aff_GetSportID('Casino')

select @SPQMAmount=QMTurnOver
from SportType (nolock)
where SportID=  @SportsBookID

select @HRQMAmount=QMTurnOver
from SportType (nolock)
where SportID= @HorseRacingID

select @CAQMAmount=QMTurnOver, @CAQMDeposit = QMDeposit
from SportType (nolock)
where SportID= @CasinoID


 --Get First date and last date and current date in order to calculate turnover
Select @CurrDate =  convert(varchar(10),current_timestamp,120),
	@FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime),
	@LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))
	
Select @LastDay = (case when @LastDay >= @CurrDate then dateadd(d, -1, @CurrDate) else @LastDay end)
	
insert into @TblResult
Select IBCCustId, Sum(SPTurnOver) as SPTurnOver, Sum(HRTurnOver) as HRTurnOver, Sum(CATurnOver) as CATurnOver, Sum(CADeposit) as CADeposit
From
(
	--Calculate for SP
	Select IBCCustID,--MemberDaily
		sum(TurnOver* AffExRate) as SPTurnOver,
		0 as HRTurnOver,
		0 as CATurnOver,
		0 as CADeposit
	From MemberDaily with (nolock)
	where SportType=@SportsBookID and Winlostdate  between @FirstDay and @LastDay and AffID=@AffID
	Group by IBCCustID
	
	Union All
	
	Select m.IBCCustID,--Bettrans
		sum(abs(b.Stake) * m.AffExRate) as SPTurnOver,
		0 as HRTurnOver,
		0 as CATurnOver,
		0 as CADeposit
	From bodb02.dbo.Bettrans b with (nolock)
		inner join @MemList m on b.CustId = m.IBCCustId
	where datediff(m, @FirstDay, @CurrDate) = 0
		and Winlostdate = @CurrDate
		and bettype < 19000 and bettype not in (31,32,33,41,42,43)
		  and bettype not between 71 and 120 --Not include Casino and Number Game
		and StatusID not in (101, 102, 103, 121,1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')		
	Group by IBCCustID
		
	Union All
	
	--Calculate for HR	
	Select IBCCustID,
		0 as SPTurnOver,
		sum(TurnOver* AffExRate) as HRTurnOver,
		0 as CATurnOver,
		0 as CADeposit
	From MemberDaily with (nolock)
	where SportType=@HorseRacingID and Winlostdate  between @FirstDay and @LastDay and AffID=@AffID
	Group by IBCCustID
	
	Union All
	
	Select m.IBCCustID,--Bettrans
		0 as SPTurnOver,
		Sum(case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(abs(stake),0)/2 else isnull(abs(stake),0) end * isnull(m.AffExRate, 0)) as HrTurnOver,
		0 as CATurnOver,
		0 as CADeposit
	From bodb02.dbo.Bettrans b with (nolock)
		inner join @MemList m on b.CustId = m.IBCCustId
	where datediff(m, @FirstDay, @CurrDate) = 0
		and Winlostdate = @CurrDate
		and bettype in (31,32,33,41,42,43)
		and StatusID not in (101, 102, 103, 121,1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')		
	Group by IBCCustID

	Union All

	--Calculate for CA	
	Select IBCCustID,
		0 as SPTurnOver,
		0 as HRTurnOver,
		sum(TurnOver * AffExRate) as CATurnOver,
		sum(Deposit * AffExRate) as CADeposit
	From MemberDaily with (nolock)
	where SportType=@CasinoID and Winlostdate  between @FirstDay and @LastDay and AffID=@AffID
	Group by IBCCustID
) tmp
Group by IBCCustId
Having Sum(SPTurnOver) > 0 or Sum(HRTurnOver) > 0 or Sum(CATurnOver) > 0 or Sum(CADeposit) > 0
	

select @NRows=count(distinct IBCCustID)    
FROM @TblResult

if(isnull(@NRows,0)=0)    
   return    
  
DECLARE @RowStart int, @RowEnd int  
	
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       

select mi.username as username,
	mi.IBCUserName,
	m.SPTurnOver, 
	m.IsSPQM,
	m.HRTurnOver, 
	m.IsHRQM,
	m.CATurnOver,
	m.IsCAQM
from MemberInfo mi (nolock)
	inner join 
	(select ROW_NUMBER() OVER(ORDER BY coalesce(SPTurnOver, HRTurnOver) desc, IBCCustID) AS TheCount,  
		IBCCustId,
		SPTurnOver, 
		(case when isnull(SPTurnOver,0)>=@SPQMAmount then 1 else 0 end) as IsSPQM,
		HRTurnOver, 
		(case when isnull(HRTurnOver,0)>=@HRQMAmount then 1 else 0 end) as IsHRQM,
		CATurnOver, 
		(case when isnull(CATurnOver,0)>=@CAQMAmount and isnull(CADeposit,0)>=@CAQMDeposit then 1 else 0 end) as IsCAQM
	from @TblResult
	) m on mi.IBCCustId = m.IBCCustId
where m.TheCount between @RowStart and @RowEnd    

GO
GRANT EXECUTE ON [dbo].[Aff_ReportQMDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportQMDetail] TO [VNTeam] 