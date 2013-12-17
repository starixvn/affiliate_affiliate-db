 --The old data from rptDepWinlost has problem with turnover for Horse Racing bettype 33,43 and liveawayscore=0
 --so we accept it is wrong for old data but since Nov 2009 we must calculate exactly data for HRTurnOver
 --This script just reupdates the data for Nov - 2009
 SET NOCOUNT ON
GO
declare @FromDate smalldatetime,@ToDate smalldatetime
select @FromDate = '1 NOV 2009',@ToDate='30 NOV 2009'


declare @HorseRacingID int
select @HorseRacingID=dbo.Aff_GetSportID('Horse Racing')

DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME  
SELECT @BalanceUpDay = winlostdate FROM bodb02.dbo.Bettrans WITH(NOLOCK) WHERE bettype = 100 and matchid = 0 and custid = 3  
SELECT @MoveBetsDay = max(winlostdate) FROM bodb02.dbo.Bettrans14 WITH(NOLOCK)  

print @BalanceUpDay
print @MoveBetsDay

CREATE TABLE #Data(
	IBCCustID int,     	
    WinlostDate smalldatetime,   
	TurnOver money	
)
insert into #Data(IBCCustID,	
    WinlostDate,    
	TurnOver
)
select b.custid, 
       b.WinlostDate,      
        isnull(sum(CASE WHEN bettype in (33,43) AND liveawayscore = 0 THEN stake/2 ELSE stake END),0) as TurnoverHR        
from DB06.bodb_archive.dbo.bettrans_bk b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @FromDate and @BalanceUpDay
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')
		      and ruben=1
		group by b.custid ,
		         b.winlostdate	      		
				
union all
 select b.custid,  
        b.WinlostDate,        
        isnull(sum(CASE WHEN bettype in (33,43) AND liveawayscore = 0 THEN stake/2 ELSE stake END),0) as TurnoverHR        
from bodb02.dbo.bettrans14 b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @BalanceUpDay and @MoveBetsDay
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')
		      and ruben=1
		group by b.custid ,
		         b.winlostdate		         
union all
  select b.custid,   
        b.WinlostDate,        
        isnull(sum(CASE WHEN bettype in (33,43) AND liveawayscore = 0 THEN stake/2 ELSE stake END),0) as TurnoverHR		
from bodb02.dbo.bettrans b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate > @MoveBetsDay
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')		      
		group by b.custid ,
		         b.winlostdate
select * from #Data with (nolock)


Update d
set d.Turnover=isnull(d1.Turnover,0)
from MemberDaily d   with (rowlock,updlock)
     inner join #Data d1 with (nolock) on d1.IBCCustID=d.IBCCustID and d1.WinlostDate=d.WinlostDate
where d.SportType=@HorseRacingID and d.Winlostdate between @FromDate and @ToDate

drop table #Data