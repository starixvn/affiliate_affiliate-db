/****** Object:  Stored Procedure dbo.IA_CheckSum    Script Date: 11/1/2012 10:16:41 AM ******/  
ALTER PROCEDURE [dbo].[IA_CheckSum]  
	@IsMatch bit = 1 output,  
	@Date smalldatetime = null  
AS  
/*  
Created: @Johnny  
Task :  
 - Check the summary of deposit, withdrawal, bonus, adjustment, turnover, outstanding, winlost, psp, marketing, memoddsfee of MemberDailyIA table with bettrans  
DB: DB06.bodb02  
Original: [Aff_CheckSum]  
Revisions:      
   - 20121019@Johnny : Add parameter @Date to Check  
   - 20130313@Johnny : Fix range bettype (bettype < 999 and exclude bettype between 31 and 120)
*/  
  
Set Nocount On  
  
IF @Date < '1 Nov 2011' or @Date>current_timestamp RETURN    
    
DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME  
  , @Winlostdate smalldatetime, @SportbookId int, @HorseRacingId int  
--Check sum data for the day before yesterday  
select @Winlostdate = isnull(@Date, dateadd(d, 0, datediff(d, 0, current_timestamp) - 2))  
select @SportbookId = 1, @HorseRacingId = 2  
SELECT @BalanceUpDay = winlostdate FROM Bettrans WITH(NOLOCK) WHERE bettype = 20000 and matchid = 0 and custid = 3     
SELECT @MoveBetsDay = max(eventdate) FROM match14 WITH(NOLOCK)      
  
DECLARE @AffExchange table(ExchangeID int primary key,ActualRate float,ActualRate2 float)    

INSERT INTO @AffExchange(ExchangeID,ActualRate,ActualRate2)    
SELECT exchangeid, actualrate, eur  
FROM ExchangeDailyOanda with(nolock)    
WHERE exchangedate = @Winlostdate    
    
  --Table contains all 12BET deposit Income Access Member    
CREATE TABLE #MemberInfo(    
	IBCCustID int primary key,         
	Currency int,    
	UserName nvarchar(30),    
	IBCUserName varchar(30),    
	IBCAgentID int,    
	DepositCustID int     
)      
    
Insert into #MemberInfo(IBCCustID,Currency,UserName,IBCUserName,IBCAgentID,DepositCustID)    
Select CustID,Currency, REPLACE(UserName2,'12bet$',''),username,recommend,refcode2    
from customer with(nolock)   
where roleid=1    
	and recommend in (    
		select custid    
		from customer c with(nolock)    
		where roleid = 2    
		and username in (select '12bet'+cast(currency as varchar(4))+'04' from exchange)    
	)    
    
--select * from #MemberInfo (nolock)    
    
CREATE TABLE #Data(     
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
	DrawGameHR money    
)    
  
IF @Winlostdate > @MoveBetsDay    
BEGIN    
 ---Add SportsBook,Horse Racing, Casino    
     
	 insert into #Data(    
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
		WinlostHR   
	 )    
	 select   
		isnull(sum(case bettype when 22001 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Deposit,        
		-isnull(sum(case when bettype in (22002,22003) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Withdrawal,    
		isnull(sum(case bettype when 22004 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Bonus,    
		isnull(sum(case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Adjustment,        
		isnull(sum(case when bettype < 999 and bettype not in (31,32,33,41,42,43) then isnull(abs(stake),0) else 0 end),0) as Turnover,    
		isnull(sum(case when bettype < 999 and bettype not in (31,32,33,41,42,43) and StatusID=111/*status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGame,    
		isnull(sum(case when bettype < 999 and bettype not in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as Outstanding,    
		isnull(sum(case when bettype < 999 and bettype not in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as Winlost,    
		isnull(sum(case when bettype in (31,32,33,41,42,43) then  (case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(abs(stake),0)/2 else isnull(abs(stake),0) end)                                    
		else 0     
		end),0) as TurnoverHR,    
		isnull(sum(case when bettype in (31,32,33,41,42,43) and StatusID=111/* status in ('DRAW')*/ then isnull(abs(stake),0) else 0 end),0) as DrawGameHR,    
		isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=0 then isnull(abs(actual_stake),0) else 0 end),0) as OutstandingHR,    
		isnull(sum(case when bettype in (31,32,33,41,42,43) and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0) as WinlostHR  
         
	from bettrans b with (nolock)      
		INNER JOIN  #MemberInfo m with (nolock) on m.IBCCustID=b.CustID      
		INNER JOIN @AffExchange e on e.ExchangeID=b.currency    
	where winlostdate = @winlostdate    
		and (bettype<999 or bettype in (22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005))    
		and bettype not between 31 and 120 --Not include Casino and Number Game    
		and StatusID not in (101, 102, 103, 121, 1)        
		and b.custid > 0      
  
END    
ELSE IF @Winlostdate < @BalanceUpDay    
BEGIN    
	insert into #Data(   
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
		WinlostHR   
	)    
	select     
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
		isnull(t1.WinlostHR,0) as WinlostHR  
	from     
		(select b.custid,     
			m.UserName,    
			m.IBCUserName,    
			m.IBCAgentID,    
			m.DepositCustID,       
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
			m.currency,    
			e.ActualRate2,    
			e.ActualRate         
		from bodb_archive.dbo.bettrans_bk b with (nolock)      
			INNER JOIN #MemberInfo m on m.IBCCustID=b.custid    
			INNER JOIN @AffExchange e on e.ExchangeID=b.currency    
		where winlostdate = @winlostdate    
			and bettype<999    
			and bettype not between 31 and 120 --Not include Casino and Number Game    
			and StatusID not in (101, 102, 103, 121)        
		group by b.custid , m.currency,    
			e.ActualRate2,    
			e.ActualRate,m.UserName,    
			m.IBCUserName,    
			m.IBCAgentID,    
			m.DepositCustID       
		) t1    
  
	FULL OUTER join  
  
		(select  b1.custid,    
			m.UserName,    
			m.IBCUserName,    
			m.IBCAgentID,    
			m.DepositCustID,            
			b1.Deposit,    
			b1.Withdrawal,    
			b1.Bonus,     
			b1.Adjustment,    
			m.currency,    
			e.ActualRate2,    
			e.ActualRate    
		from    
			(select custid,    
				sum( case when bettype=22001 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Deposit,    
				-sum( case when bettype in (22002,22003) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Withdrawal,    
				sum( case when bettype=22004 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Bonus,     
				sum( case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Adjustment     
           
			from bodb_Archive.dbo.transfer_bk b with (nolock)     
			where winlostdate=@Winlostdate    
				and recommend in (    
					select  distinct IBCAgentID     
					from #MemberInfo m with(nolock)          
				)    
				and bettype in(22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005)    
			group by custid    
			) b1    
			INNER JOIN  #MemberInfo m on m.IBCCustID=b1.custid    
			INNER JOIN @AffExchange e on e.ExchangeID=m.currency    
			) t2 on t2.custid=t1.custid   
         
END     
ELSE    
BEGIN    
	insert into #Data(    
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
		WinlostHR    
	)    
	select    
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
		isnull(t1.WinlostHR,0) as WinlostHR   
	from     
		(select b.custid,    
			m.UserName,    
			m.IBCUserName,    
			m.IBCAgentID,    
			m.DepositCustID,       
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
			m.currency,    
			e.ActualRate2,    
			e.ActualRate    
         
		from bettrans14 b with (nolock)      
			INNER JOIN #MemberInfo m on m.IBCCustID=b.custid    
			INNER JOIN @AffExchange e on e.ExchangeID=b.currency    
		where winlostdate = @winlostdate    
			and bettype<999    
			and bettype not between 31 and 120 --Not include Casino and Number Game    
			and StatusID not in (101, 102, 103, 121)        
		group by b.custid , m.currency,    
			e.ActualRate2,    
			e.ActualRate,m.UserName,    
			m.IBCUserName,    
			m.IBCAgentID,    
			m.DepositCustID    
		) t1    
	FULL OUTER join(    
		select b.custid,    
			m.UserName,    
			m.IBCUserName,    
			m.IBCAgentID,    
			m.DepositCustID,    
			sum( case when bettype=22001 then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Deposit,    
			-sum( case when bettype in (22002,22003) then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Withdrawal,    
			sum( case when bettype=22004 then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Bonus,     
			sum( case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Adjustment,    
			m.currency,    
			e.ActualRate2,    
			e.ActualRate                 
		from  bettrans b with (nolock)     
			INNER JOIN #MemberInfo m on m.IBCCustID=b.custid    
			INNER JOIN @AffExchange e on e.ExchangeID=m.currency    
		where winlostdate=@Winlostdate         
			and bettype in(22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005)    
			group by b.custid , m.currency,    
			e.ActualRate2,    
			e.ActualRate,    
			m.UserName,    
			m.IBCUserName,    
			m.IBCAgentID,    
			m.DepositCustID    
       
		) t2 on t2.custid=t1.custid                  
       
END      
    
    
--Bettrans variables  
Declare @BT_Deposit money, @BT_Withdrawal money, @BT_Bonus money, @BT_Adjustment money, @BT_Turnover money, @BT_DrawGame money, @BT_Outstanding money, @BT_Winlost money,  
  @BT_TurnoverHR money, @BT_DrawGameHR money, @BT_OutstandingHR money, @BT_WinlostHR money  
--MemberDaily variables  
Declare @MD_Deposit money, @MD_Withdrawal money, @MD_Bonus money, @MD_Adjustment money, @MD_Turnover money, @MD_DrawGame money, @MD_Outstanding money, @MD_Winlost money,  
  @MD_TurnoverHR money, @MD_DrawGameHR money, @MD_OutstandingHR money, @MD_WinlostHR money  
  
--Calculate Sum for bettrans table  
SELECT    
	@BT_Deposit = sum(isnull(Deposit, 0)),     
	@BT_Withdrawal = sum(isnull(Withdrawal, 0)),      
	@BT_Bonus = sum(isnull(Bonus, 0)),     
	@BT_Adjustment = sum(isnull(Adjustment, 0)),     
	@BT_Turnover = sum(isnull(Turnover, 0)),     
	@BT_Outstanding = sum(isnull(Outstanding, 0)),    
	@BT_Winlost = sum(isnull(Winlost, 0)),       
	@BT_DrawGame = sum(isnull(DrawGame, 0)),     
	@BT_TurnoverHR = sum(isnull(TurnoverHR, 0)),     
	@BT_OutstandingHR = sum(isnull(OutstandingHR, 0)),    
	@BT_WinlostHR = sum(isnull(WinlostHR, 0)),    
	@BT_DrawGameHR = sum(isnull(DrawGameHR, 0))  
FROM #Data d with (nolock)   
WHERE  Deposit<>0 or         
	Withdrawal<>0 or      
	Bonus<>0 or     
	Adjustment<>0 or      
	TurnOver<>0 or     
	DrawGame<>0 or     
	Outstanding<>0 or     
	Winlost<>0  or  
	TurnOverHR<>0 or      
	DrawGameHR<>0 or      
	OutstandingHR<>0 or      
	WinlostHR<>0  
  
--Calculate Sum for MemberDailyIA table  
select   
	@MD_Deposit = isnull(sum(isnull(Deposit, 0)), 0),   
	@MD_Withdrawal = isnull(sum(isnull(Withdrawal, 0)), 0),   
	@MD_Bonus = isnull(sum(isnull(Bonus, 0)), 0),   
	@MD_Adjustment = isnull(sum(isnull(Adjustment, 0)), 0),   
	@MD_Turnover = isnull(sum(isnull(Turnover, 0)), 0),   
	@MD_DrawGame = isnull(sum(isnull(DrawGame, 0)), 0),   
	@MD_Outstanding = isnull(sum(isnull(Outstanding, 0)), 0),   
	@MD_Winlost = isnull(sum(isnull(Winlost, 0)), 0)  
from bodb_report.dbo.MemberDailyIA nolock  
where WinlostDate = @Winlostdate  
	and sporttype = @SportbookId  
/*  
select   
	@MD_TurnoverHR = isnull(sum(isnull(Turnover, 0)), 0),   
	@MD_DrawGameHR  = isnull(sum(isnull(DrawGame, 0)), 0),   
	@MD_OutstandingHR = isnull(sum(isnull(Outstanding, 0)), 0),   
	@MD_WinlostHR = isnull(sum(isnull(Winlost, 0)), 0)  
from bodb_report.dbo.MemberDailyIA nolock  
where WinlostDate = @Winlostdate  
	and sporttype = @HorseRacingId  */
  
  
drop table #Data    
drop table #MemberInfo  
  
  
--Check sum data between Bettrans and MemberDailyIA  
if(@MD_Deposit <> @BT_Deposit   
	or @MD_Withdrawal <> @BT_Withdrawal   
	or @MD_Bonus <> @BT_Bonus   
	or @MD_Adjustment <> @BT_Adjustment   
	or @MD_Turnover <> @BT_Turnover   
	or @MD_Outstanding <> @BT_Outstanding  
	or @MD_Winlost <> @BT_Winlost  
	or @MD_DrawGame <> @BT_DrawGame   
	--or @MD_TurnoverHR <> @BT_TurnoverHR     
	--or @MD_OutstandingHR <> @BT_OutstandingHR     
	--or @MD_WinlostHR <> @BT_WinlostHR     
	--or @MD_DrawGameHR <> @BT_DrawGameHR     
 )  
Begin  
	Select @IsMatch = 0  
   
	select 'Summary Data in Bettrans' as Description,   
		@BT_Deposit as Deposit,     
		@BT_Withdrawal as Withdrawal,      
		@BT_Bonus as Bonus,     
		@BT_Adjustment as Adjustment,     
		@BT_Turnover as Turnover,     
		@BT_Outstanding as Outstanding,    
		@BT_Winlost as Winlost,       
		@BT_DrawGame as DrawGame--,     
		--@BT_TurnoverHR as TurnoverHR,     
		--@BT_OutstandingHR as OutstandingHR,    
		--@BT_WinlostHR as WinlostHR,    
		--@BT_DrawGameHR as DrawGameHR  
	Union All  
	select 'Summary Data in MemberDailyIA' as Description,  
		@MD_Deposit as Deposit,     
		@MD_Withdrawal as Withdrawal,      
		@MD_Bonus as Bonus,     
		@MD_Adjustment as Adjustment,     
		@MD_Turnover as Turnover,     
		@MD_Outstanding as Outstanding,    
		@MD_Winlost as Winlost,       
		@MD_DrawGame as DrawGame--,     
		--@MD_TurnoverHR as TurnoverHR,     
		--@MD_OutstandingHR as OutstandingHR,    
		--@MD_WinlostHR as WinlostHR,    
		--@MD_DrawGameHR as DrawGameHR  
	return  
end  
  
Select @IsMatch = 1


GO 
GRANT VIEW DEFINITION ON [dbo].[IA_CheckSum] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[IA_CheckSum] TO [bodbAdminNet]
GO 