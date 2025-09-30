ALTER PROCEDURE [dbo].[Aff_MemberDailyApiSel]
	@winlostdate datetime
AS
/*
	Created: 20130304@Johnny
	Task : Get summary data for members of livebet365
	DB: DB054.bodb02

	Revisions:				
					  

	Param's Explanation:
	• @winlostdate: The data need to summary
*/
DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @AgentUsername nvarchar(50), @AgentId int
SELECT @BalanceUpDay = winlostdate FROM bodb02.dbo.Bettrans WITH(NOLOCK) WHERE bettype = 20000 and matchid = 0 and custid = 3  
SELECT @MoveBetsDay = max(eventdate) FROM bodb02.dbo.match14 WITH(NOLOCK)   

Declare @MemberList table(IBCCustId int, Currency nvarchar(50), recommend int)

--Select list customer under agent 02(member register via affiliate program)
insert into @MemberList(IBCCustId, Currency, recommend)
SELECT 
	c.custid, 	
	e.Currency,
	c.recommend
from custinfo c with(nolock)	
	inner join exchange e with (nolock) on c.currency=e.exchangeid
where c.roleid=1
	and c.recommend in (select custid--List Agent currency 02
					from bodb02.dbo.custinfo ci with (nolock)
						inner join exchange e with (nolock) on ci.currency=e.exchangeid	 	
					where roleid=2 and 
					      ci.username = 'LB365' + e.currency + '02'
					) 

--Create tmp table to store return data
CREATE TABLE #Data(
	IBCCustID int primary key,     
	Currency nvarchar(50),
	Deposit money,
	Withdrawal money,		
	Bonus money,
	Adjustment money,	
	TurnOver money,
	Outstanding money,
	Winlost money,
	DrawGame money,   
	TurnOverHR money,
	OutstandingHR money,
	WinlostHR money,
	DrawGameHR money,   	
	PSP money,
	Marketing money
)


IF @Winlostdate > @MoveBetsDay
BEGIN
	---Add SportsBook,Horse Racing, Casino
	insert into #Data(
		IBCCustID,		
		Deposit,				
		Withdrawal,   
		Bonus,
		Adjustment,
		TurnOver,
		DrawGame,
		Outstanding,
		Winlost,
		TurnOverHR,
		DrawGameHR,
		OutstandingHR,
		WinlostHR,				
		Currency     
	)
	select b.custid,
			isnull(sum(case bettype when 22001 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Deposit,				
			-isnull(sum(case when bettype in (22002,22003) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Withdrawal,
			isnull(sum(case bettype when 22004 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Bonus,
			isnull(sum(case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Adjustment,				
			isnull(sum(case when bettype < 19000 and bettype not in (31,32,33,41,42,43) then isnull(abs(stake),0) else 0 end),0) as Turnover,
			isnull(sum(case when bettype < 19000 and bettype not in (31,32,33,41,42,43) and StatusID=111/*status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGame,
			isnull(sum(case when bettype < 19000 and bettype not in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as Outstanding,
			isnull(sum(case when bettype < 19000 and bettype not in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as Winlost,
			isnull(sum(case when bettype in (31,32,33,41,42,43) then  (case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(abs(stake),0)/2 else isnull(abs(stake),0) end)                                
							else 0 
						end),0) as TurnoverHR,
			isnull(sum(case when bettype in (31,32,33,41,42,43) and StatusID=111/* status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGameHR,
			isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as OutstandingHR,
			isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as WinlostHR,
			m.currency 
					
	from bodb02.dbo.bettrans b with (nolock)		
		INNER JOIN @MemberList m on m.IBCCustID=b.custid
	where winlostdate = @winlostdate
			and (bettype<19000 or bettype in (22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005))
			and bettype not between 71 and 120 --Not include Casino and Number Game
			and StatusID not in (101, 102, 103, 121, 1)
			--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'
			and b.custid > 0		
					   
	group by b.custid,m .currency

	
END
ELSE IF @Winlostdate < @BalanceUpDay
BEGIN
		insert into #Data(
		IBCCustID,		
		Deposit,				
		Withdrawal,   
		Bonus,
		Adjustment,
		TurnOver,
		DrawGame,
		Outstanding,
		Winlost,
		TurnOverHR,
		DrawGameHR,
		OutstandingHR,
		WinlostHR,				
		Currency
	)
	select coalesce(t1.custid,t2.custid),  
	   isnull(t2.Deposit,0) as Deposit,				
	   isnull(t2.Withdrawal,0) as Withdrawal,   
	   isnull(t2.Bonus,0) as Bonus,
	   isnull(t2.Adjustment,0) as Adjustment,
		isnull(t1.TurnOver,0) as TurnOver,
		isnull(t1.DrawGame,0) as DrawGame,
		isnull(t1.Outstanding,0) as Outstanding,
		isnull(t1.Winlost,0) as Winlost,
		isnull(t1.TurnOverHR,0) as TurnOverHR,
		isnull(t1.DrawGameHR,0) as DrawGameHR,
		isnull(t1.OutstandingHR,0) as OutstandingHR,
		isnull(t1.WinlostHR,0) as WinlostHR,				
		coalesce(t1.Currency,t2.currency) as Currency
	from 
		(select b.custid,			
			isnull(sum(case when bettype not in (31,32,33,41,42,43) then isnull(abs(stake),0) else 0 end),0) as Turnover,
			isnull(sum(case when bettype not in (31,32,33,41,42,43) and StatusID=111 /*status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGame,
			isnull(sum(case when bettype not in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as Outstanding,
			isnull(sum(case when bettype not in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as Winlost,
			isnull(sum(case when bettype in (31,32,33,41,42,43) then  (case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(abs(stake),0)/2 else isnull(abs(stake),0) end)                                
							else 0 
						end),0) as TurnoverHR,
			isnull(sum(case when bettype in (31,32,33,41,42,43) and StatusID=111/* status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGameHR,
			isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as OutstandingHR,
			isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as WinlostHR,
			m.currency					
		from DB06.bodb_archive.dbo.bettrans_bk b with (nolock)		
			INNER JOIN @MemberList m on m.IBCCustID=b.custid
		where winlostdate = @winlostdate
			 and bettype<19000
			 and bettype not between 71 and 120 --Not include Casino and Number Game
			 and StatusID not in (101, 102, 103, 121, 1)
			 --and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'		 
		group by b.custid , m.currency
	   ) t1
	   FULL OUTER join
	   (
		select custid,
			sum( case when bettype=22001 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Deposit,
			-sum( case when bettype in (22002,22003) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Withdrawal,
			sum( case when bettype=22004 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Bonus, 
			sum( case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Adjustment,
			m.Currency
		from DB06.bodb_Archive.dbo.transfer_bk b with (nolock) 
			inner join @MemberList m on b.CustId = m.IBCCustId
		where winlostdate=@Winlostdate
			and bettype in(22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005)
		group by custid, m.Currency
			
	   ) t2 on t2.custid=t1.custid    
		   
END 
ELSE
BEGIN
	insert into #Data(
		IBCCustID,		
		Deposit,				
		Withdrawal,   
		Bonus,
		Adjustment,
		TurnOver,
		DrawGame,
		Outstanding,
		Winlost,
		TurnOverHR,
		DrawGameHR,
		OutstandingHR,
		WinlostHR,				
		Currency
	)
	 select coalesce(t1.custid,t2.custid),  
	   isnull(t2.Deposit,0) as Deposit,				
	   isnull(t2.Withdrawal,0) as Withdrawal,   
	   isnull(t2.Bonus,0) as Bonus,
	   isnull(t2.Adjustment,0) as Adjustment,
		isnull(t1.TurnOver,0) as TurnOver,
		isnull(t1.DrawGame,0) as DrawGame,
		isnull(t1.Outstanding,0) as Outstanding,
		isnull(t1.Winlost,0) as Winlost,
		isnull(t1.TurnOverHR,0) as TurnOverHR,
		isnull(t1.DrawGameHR,0) as DrawGameHR,
		isnull(t1.OutstandingHR,0) as OutstandingHR,
		isnull(t1.WinlostHR,0) as WinlostHR,				
		coalesce(t1.Currency,t2.currency) as Currency
	from 
		(select b.custid,			
				isnull(sum(case when bettype not in (31,32,33,41,42,43) then isnull(abs(stake),0) else 0 end),0) as Turnover,
				isnull(sum(case when bettype not in (31,32,33,41,42,43) and StatusID=111/* status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGame,
				isnull(sum(case when bettype not in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as Outstanding,
				isnull(sum(case when bettype not in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as Winlost,
				isnull(sum(case when bettype in (31,32,33,41,42,43) then  (case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(abs(stake),0)/2 else isnull(abs(stake),0) end)                                
								else 0 
						   end),0) as TurnoverHR,
				isnull(sum(case when bettype in (31,32,33,41,42,43) and StatusID=111 /*status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGameHR,
				isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as OutstandingHR,
				isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as WinlostHR,
				m.currency 
					
		from bodb02.dbo.bettrans14 b with (nolock)		
			INNER JOIN @MemberList m on m.IBCCustID=b.custid
		where winlostdate = @winlostdate
			 and bettype<19000
			 and bettype not between 71 and 120 --Not include Casino and Number Game
			  and StatusID not in (101, 102, 103, 121, 1)
			 --and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'			 
		group by b.custid, m.currency
	   ) t1
	   FULL OUTER join(
			select b.custid,
					sum( case when bettype=22001 then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Deposit,
					-sum( case when bettype in (22002,22003) then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Withdrawal,
					sum( case when bettype=22004 then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Bonus, 
					sum( case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Adjustment,
					m.currency 												
			from  bodb02.dbo.bettrans b with (nolock) 
				 INNER JOIN @MemberList m on m.IBCCustID=b.custid
			 where winlostdate=@Winlostdate				 
				and bettype in(22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005)
			group by b.custid, m.currency
			
	   ) t2 on t2.custid=t1.custid              		   
	  
END  

Select * from #Data

GO
GRANT EXECUTE ON [dbo].[Aff_MemberDailyApiSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDailyApiSel] TO [vnteam]
