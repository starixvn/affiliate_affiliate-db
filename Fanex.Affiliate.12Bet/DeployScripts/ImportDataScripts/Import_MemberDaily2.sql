 
USE [Affiliate_12BET]

SET NOCOUNT ON
GO
declare @FromDate smalldatetime,@ToDate smalldatetime ,@HRWinlostDate smalldatetime
select @FromDate='01 Nov 2009' --min (winlostdate) from DB06.bodb_report.dbo.rptDepWinlost r with(nolock)

select @ToDate = '30 Nov 2009',@HRWinlostDate='2009-07-14 00:00:00'

if(@FromDate>@ToDate)
   return
if(@HRWinlostDate<@FromDate)
  select @HRWinlostDate=@FromDate

if exists (select 1 from MemberDaily with (nolock) WHERE winlostdate between @FromDate and @ToDate )
  begin
      DELETE FROM MemberDaily WHERE winlostdate between @FromDate and @ToDate
end
  
declare @SportsBookID int,@HorseRacingID int
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')



--Insert SportsBook

INSERT INTO MemberDaily(
	WinlostDate,
	IBCCustID,
	Sporttype,
	Currency,
	Deposit,
	Withdrawal,	
	Bonus,
	Adjustment,
	Turnover,
	Outstanding,
	Winlost,
	AWinlost,
    ABonus,
	AffExRate,
	MemberExRate,	
	DrawGame,
	PSP,
	Marketing,
    AffID
)

SELECT 
	r.WinlostDate,
	m.IBCCustID, 
	@SportsBookID as SportType, --sporttype	
	m.currency,
	Deposit, 
	Withdrawal, 	
	Bonus, 
	Adjustment, 
	r.Turnover, 
	r.Outstanding, 
	Winloss, 
	aWinlost,
    aBonus,
	aExRate, 
	actualrate,	
	r.DrawGame, 
	0 as PSP,
	0 as Marketing,
    m.AffID
FROM DB06.bodb_report.dbo.rptDepWinlost r with(nolock)	
	inner join MemberInfo m with (nolock) on r.CustID = m.IBCCustID	
WHERE WinlostDate between @FromDate and @ToDate 

--Insert Horse Racing rows . Recalculate old data

CREATE TABLE #Data(
	IBCCustID int,     	
    WinlostDate smalldatetime,
    Currency int,
	TurnOver money,
	Outstanding money,
    Winlost money,
    DrawGame money,      
    AffExRate float,
    MemberExRate float,        
    AffID int
)
insert into #Data(IBCCustID,	
    WinlostDate,
    Currency,
	TurnOver,
	Outstanding,
    Winlost,
    DrawGame,   
    MemberExRate,   
    AffExRate,            
    AffID
)
select b.custid, 
       b.WinlostDate,
        b.Currency, 
        isnull(sum(CASE WHEN bettype in (33,43) AND liveawayscore = 0 THEN stake/2 ELSE stake END),0) as TurnoverHR,
        0 as OutstandingHR,
        isnull(sum(isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0)),0) as WinlostHR,
		isnull(sum(case when status in ('DRAW') then isnull(stake,0) else 0 end),0) as DrawGameHR,
		e.ActualRate,
		e.ActualRate2,
		m.AffID
from DB06.bodb_archive.dbo.bettrans_bk b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @HRWinlostDate and @ToDate
		      and bettype between 31 and 49--and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')
		      and ruben=1
		group by b.custid ,
		         b.winlostdate,
		         b.currency,
                e.ActualRate2,
                e.ActualRate,
                m.AffID   		 		
				
union all
 select b.custid,  
        b.WinlostDate,
        b.Currency, 
        isnull(sum(CASE WHEN bettype in (33,43) AND liveawayscore = 0 THEN stake/2 ELSE stake END),0) as TurnoverHR,
        0 as OutstandingHR,
        isnull(sum(isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0)),0) as WinlostHR,
		isnull(sum(case when status in ('DRAW') then isnull(stake,0) else 0 end),0) as DrawGameHR,
		e.ActualRate,
		e.ActualRate2,
		m.AffID
from bodb02.dbo.bettrans14 b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @HRWinlostDate and @ToDate
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')
		      and ruben=1
		group by b.custid ,
		         b.winlostdate,
		         b.currency,
                e.ActualRate2,
                e.ActualRate,
                m.AffID   	
union all
  select b.custid,   
        b.WinlostDate,
        b.Currency, 
        isnull(sum(CASE WHEN bettype in (33,43) AND liveawayscore = 0 THEN stake/2 ELSE stake END),0) as TurnoverHR,
		isnull(sum(case when ruben=0 then isnull(actual_stake,0) else 0 end),0) as OutstandingHR,
		isnull(sum(case when ruben=1 then isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0) else 0 end),0) as WinlostHR,
		isnull(sum(case when status in ('DRAW') then isnull(stake,0) else 0 end),0) as DrawGameHR,
		e.ActualRate,
		e.ActualRate2,
		m.AffID
from bodb02.dbo.bettrans b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @HRWinlostDate and @ToDate
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')		      
		group by b.custid ,
		         b.winlostdate,
		         b.currency,
                e.ActualRate2,
                e.ActualRate,
                m.AffID   	
select * from #Data with (nolock)

 
INSERT INTO MemberDaily(
	WinlostDate,
	IBCCustID,
	Sporttype,
	Currency,
	Deposit,
	Withdrawal,	
	Bonus,
	Adjustment,
	Turnover,
	Outstanding,
	Winlost,
	AWinlost,
    ABonus, 
	AffExRate,
	MemberExRate,	
	DrawGame,
	PSP,
	Marketing,
    AffID
)

SELECT 
	r.WinlostDate,
	r.IBCCustID, 
	@HorseRacingID as SportType, --sporttype	
	r.currency,
	0 as Deposit, 
	0 as Withdrawal, 	
	0 as Bonus, 
	0 as Adjustment, 
	r.Turnover,
	r.Outstanding, 
	r.Winlost, 
	0 as AWinlost,
    0 as ABonus,
	r.AffExRate,
    r.MemberExRate,
	r.DrawGame, 
	0 as PSP,
	0 as Marketing,
    r.AffID    			
FROM #Data r with(nolock)	
 where (winlost<>0 or Turnover<>0 or DrawGame<>0 or Outstanding<>0)

drop table #Data

--Reupdate SportsBook =SportsBook-HorseRacing
Update d
set d.Turnover=d.Turnover-isnull(d1.Turnover,0),
	d.Outstanding=d.Outstanding-isnull(d1.Outstanding,0), 
	d.Winlost=d.Winlost-isnull(d1.Winlost,0), 
    d.DrawGame=d.DrawGame-isnull(d1.DrawGame,0)
from MemberDaily d   with (rowlock,updlock)
     left join MemberDaily d1 with (nolock) on d1.IBCCustID=d.IBCCustID and d1.WinlostDate=d.WinlostDate and d1.SportType=@HorseRacingID
where d.SportType=@SportsBookID and d.Winlostdate between @HRWinlostDate and @ToDate	

update t 
set  t.AWinlost=coalesce(AWinlost,0),
    t.ABonus= coalesce(ABonus,0),
    t.MemberExRate=coalesce(t.MemberExRate,e.ActualRate),
    t.AffExRate=coalesce(t.AffExRate,e.ActualRate2)
from MemberDaily t with (rowlock,updlock)
     inner join Exchange e with (nolock) on e.ExchangeID=t.Currency and datediff(m,e.UpdatedTime,t.WinlostDate)=0
where t.winlostdate between @FromDate and @ToDate 
    and t.AffExRate is null or t.MemberExRate is null or t.AWinlost is null or t.ABonus is null


select * from MemberDaily (nolock) where SportType=@HorseRacingID

 
EXEC Task_Aff_MemberDailySummary '1 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '2 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '3 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '4 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '5 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '6 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '7 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '8 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '9 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '10 Nov 2009'
GO

EXEC Task_Aff_MemberDailySummary '11 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '12 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '13 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '14 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '15 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '16 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '17 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '18 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '19 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '20 Nov 2009'
GO

EXEC Task_Aff_MemberDailySummary '21 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '22 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '23 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '24 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '25 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '26 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '27 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '28 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '29 Nov 2009'
GO
EXEC Task_Aff_MemberDailySummary '30 Nov 2009'
GO