set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate datetime,
	@AffId int
AS
/*
	Created: 20090701@Peter
	Task : Summary data from 12BET Affiliates members
	DB: DB052.Affiliate_12Bet

	Revisions:				
				 20100527@Peter: Use new StatusID column instead of Status column on bettrans table   
				 20100923@Peter : Change new way to calculate PSP fee , 
						   *** we cannot recalculate the PSP before 1 Oct 2010 (coz this time we use new formula to calculate)
						   + Before 1/4/2010 
										MemWinlostFake=MemWinlost
						   + From 1/4/2010-> 30/9/2010 
						   
										MemWinlostFake = MemWinlost * NetPercentReceive
										Select @MemWinlost=[dbo].[Aff_GetMemberWinlost] (@AffID, @SportsBookID, @monthdate)
										select @NetPercentReceived = (case when @MemWinlost > 0 then 1 + @Percent else 1 - @Percent end)
							+ From 1/10/2010:
										MemWinlostFake=(case when MemberWinlost>0 then MemberWinlost * (1 + @MarketingPercent + @OddsFeePercent) - PSP
														 else  MemberWinlost * (1 - @MarketingPercent - @OddsFeePercent) - PSP
														end )
				20101228@Henry: change bettype to new range
				20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
				 - 20120514@Johnny: Just summary data for Sportbook and HorseRacing(not include Casino because casino is imported by excel file)     
							

	Param's Explanation:
	• @winlostdate: The data need to summary
*/

-- HARD CODE: not cal before 1st OCt 2010 (New formula is lauched)
-- HARD CODE: not cal before 1st Nov 2011 (Exclude Number Game from Sportsbook commission)
SET NOCOUNT ON

IF @Winlostdate < '1 Nov 2011' or @Winlostdate>current_timestamp RETURN


DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME  
SELECT @BalanceUpDay = winlostdate FROM bodb02.dbo.Bettrans WITH(NOLOCK) WHERE bettype = 20000 and matchid = 0 and custid = 3  
SELECT @MoveBetsDay = max(eventdate) FROM bodb02.dbo.match14 WITH(NOLOCK)  



DECLARE @AffExchange table(ExchangeID int primary key,ActualRate float,ActualRate2 float, DepositPercent float,WithdrawalPercent float)
if(datediff(d,@Winlostdate,current_timestamp)=0)
 BEGIN
	INSERT INTO @AffExchange(ExchangeID,ActualRate,ActualRate2,DepositPercent,WithdrawalPercent)	
	SELECT ExchangeID,ActualRate,ActualRate2,DepositPercent,WithdrawalPercent     
	from Exchange_Current e with (nolock)         
 END
else
  BEGIN
   /*
		****** Note: We must insert at least on row for each currency into Exchange table
					 when new DB is launched
  */
		INSERT INTO @AffExchange(ExchangeID,ActualRate,ActualRate2,DepositPercent,WithdrawalPercent)	
		SELECT ExchangeID,ActualRate,ActualRate2,DepositPercent,WithdrawalPercent            
		from Exchange e with (nolock)  
		   
		 where e.UpdatedTime=(
							   select max(e1.UpdatedTime) 
							   from Exchange e1 with (nolock) 
							   where e1.ExchangeID=e.ExchangeID and UpdatedTime<=@Winlostdate
							 ) 
  END
  
CREATE TABLE #Data(
	IBCCustID int primary key,     
	Currency int,
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
	AffExRate float,
	MemberExRate float,    
	PSP money,
	Marketing money,
	AffID int
)
IF @Winlostdate > @MoveBetsDay
	BEGIN
	---Add SportsBook,Horse Racing, Casino
	/*
	   Each sport type need to calculate  Winlost,Outstanding,TurnOver,Draw
	   About Deduction from Commission Tier, we don't know how to calculate now.    
	   Common Data will be added on SportsBook row 
		IBCCustID,
		Currency,
		Deposit,
		Withrawal,
		Aff2MemTransfer,
		Bonus,
		Adjustment,
		AffExRate,
		MemberExRate
		PSP,
		Marketing
		AffID*/

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
		Currency,
		AffExRate,
		MemberExRate,
		AffID       
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
				b.currency,
				e.ActualRate2,
				e.ActualRate,
				m.AffID   
					
		from bodb02.dbo.bettrans b with (nolock)		
			INNER JOIN 			
			  (
				select IBCCustID,AffID
				from MemberInfo m with(nolock)
				where AffID=@AffID and IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@Winlostdate)>=0 )
			  
			  ) m on m.IBCCustID=b.custid
			INNER JOIN @AffExchange e on e.ExchangeID=b.currency
		where winlostdate = @winlostdate
			 and (bettype<19000 or bettype in (22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005))
			 and bettype not between 71 and 120 --Not include Casino and Number Game
			 and StatusID not in (101, 102, 103, 121, 1)
			 --and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'
			 and b.custid > 0		
					   
		group by b.custid, b.currency,
				e.ActualRate2,
				e.ActualRate,
				m.AffID  

	
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
		Currency,
		AffExRate,
		MemberExRate,
		AffID   
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
		coalesce(t1.Currency,t2.currency) as Currency,
		coalesce(t1.ActualRate2,t2.ActualRate2) as AffExRate,
		coalesce(t1.ActualRate,t2.ActualRate) as MemberExRate,
		coalesce(t1.AffID,t2.AffID)   
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
				b.currency,
				e.ActualRate2,
				e.ActualRate,
				m.AffID   
					
		from DB06.bodb_archive.dbo.bettrans_bk b with (nolock)		
			INNER JOIN 			
			  (
				select IBCCustID,AffID
				from MemberInfo m with(nolock)
				where AffID=@AffID and IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@Winlostdate)>=0 )
			  
			  ) m on m.IBCCustID=b.custid
			INNER JOIN @AffExchange e on e.ExchangeID=b.currency
		where winlostdate = @winlostdate
			 and bettype<19000
			 and bettype not between 71 and 120 --Not include Casino and Number Game
			 and StatusID not in (101, 102, 103, 121, 1)
			 --and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'		 
		group by b.custid , b.currency,
				e.ActualRate2,
				e.ActualRate,
				m.AffID   
	   ) t1
	   FULL OUTER join(
			select  b1.custid,        
					b1.Deposit,
					b1.Withdrawal,
					b1.Bonus, 
					b1.Adjustment,
					m.currency,
					e.ActualRate2,
					e.ActualRate,
					m.AffID 			        

			from
			(select custid,
					sum( case when bettype=22001 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Deposit,
					-sum( case when bettype in (22002,22003) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Withdrawal,
					sum( case when bettype=22004 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Bonus, 
					sum( case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Adjustment 
							
			from DB06.bodb_Archive.dbo.transfer_bk b with (nolock) 
			 where winlostdate=@Winlostdate
				 and recommend in (
					 select  distinct recommend 
					 from MemberInfo m with(nolock)
					 where AffID=@AffID and IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@Winlostdate)>=0 ) 
				  )
				and bettype in(22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005)
			group by custid
			) b1
			 INNER JOIN 			
			  (
					select IBCCustID,AffID,currency
					from MemberInfo m with(nolock)
					where AffID=@AffID and IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@Winlostdate)>=0 )
							  
			 ) m on m.IBCCustID=b1.custid
			 INNER JOIN @AffExchange e on e.ExchangeID=m.currency
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
		Currency,
		AffExRate,
		MemberExRate,
		AffID   
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
		coalesce(t1.Currency,t2.currency) as Currency,
		coalesce(t1.ActualRate2,t2.ActualRate2) as AffExRate,
		coalesce(t1.ActualRate,t2.ActualRate) as MemberExRate,
		coalesce(t1.AffID,t2.AffID)   
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
				b.currency,
				e.ActualRate2,
				e.ActualRate,
				m.AffID   
					
		from bodb02.dbo.bettrans14 b with (nolock)		
			INNER JOIN 			
			  (
				select IBCCustID,AffID
				from MemberInfo m with(nolock)
				where AffID=@AffID and IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@Winlostdate)>=0 )
			  
			  ) m on m.IBCCustID=b.custid
			INNER JOIN @AffExchange e on e.ExchangeID=b.currency
		where winlostdate = @winlostdate
			 and bettype<19000
			  and bettype not between 71 and 120 --Not include Casino and Number Game
			 and StatusID not in (101, 102, 103, 121, 1)
			 --and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting' 
		group by b.custid , b.currency,
				e.ActualRate2,
				e.ActualRate,
				m.AffID   
	   ) t1
	   FULL OUTER join(
			select b.custid,
					sum( case when bettype=22001 then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Deposit,
					-sum( case when bettype in (22002,22003) then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Withdrawal,
					sum( case when bettype=22004 then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Bonus, 
					sum( case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(Winlost,0)-isnull(abs(actual_stake),0) else 0 end) as Adjustment,
					m.currency,
					e.ActualRate2,
					e.ActualRate,
					m.AffID 	 												
			from  bodb02.dbo.bettrans b with (nolock) 
				 INNER JOIN 			
				  (
						select IBCCustID,AffID,currency
						from MemberInfo m with(nolock)
						where AffID=@AffID and IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@Winlostdate)>=0 )
								  
				 ) m on m.IBCCustID=b.custid
				INNER JOIN @AffExchange e on e.ExchangeID=m.currency
			 where winlostdate=@Winlostdate				 
				and bettype in(22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005)
			group by b.custid , m.currency,
				e.ActualRate2,
				e.ActualRate,
				m.AffID   
			
	   ) t2 on t2.custid=t1.custid              
		   
	  
   END  



-- update for PSP from 1/4/2010->30/9/2010

/*
Update d set
	PSP = isnull(b1.dPSP,0)
from #Data d		
	left join (
		select m.IbcCustID,
				isnull(sum(di.chargefee),0) as dPSP
		from MemberInfo m
			INNER JOIN [B04-05].deposit_db.dbo.deposit_depositinfo di with (nolock) on m.DepositCustID = di.custid and m.IsRemoved=0
		where status=2 and datediff(dd, di.ApprovedDate, @winlostdate) = 0 
		group by m.IbcCustID
	) b1 on d.IbcCustID = b1.IbcCustID


Update d set
	PSP = isnull(PSP,0) + isnull(b1.wPSP,0)
from #Data d		
	left join (
		select m.IbcCustID,
				isnull(sum(wi.chargefee),0) as wPSP
		from MemberInfo	m			
			INNER JOIN [B04-05].deposit_db.dbo.deposit_withdrawalinfo wi with (nolock) on m.DepositCustID = wi.custid and m.IsRemoved=0
		where status=2 and datediff(dd, wi.ApprovedDate, @winlostdate) = 0
		group by m.IbcCustID
	) b1 on d.IbcCustID = b1.IbcCustID	
	*/
declare @SportsBookID int, @HRID int
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'), @HRID=dbo.Aff_GetSportID('Horse Racing')

DELETE FROM MemberDaily WHERE AffID=@AffID and winlostdate = @winlostdate and SportType in (@SportsBookID, @HRID)

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
	AffExRate,
	MemberExRate,	
	DrawGame,
	PSP,
	Marketing,
	AffID,
	MemOddsFee,
	MemWinlostFake
)
SELECT 
	@WinlostDate,
	IBCCustID, 
	@SportsBookID as SportType, --SportsBook
	Currency,
	Deposit, 
	Withdrawal, 	
	Bonus, 
	Adjustment, 
	Turnover, 
	Outstanding,
	Winlost,
	AffExRate,
	MemberExRate,	
	DrawGame,
	(abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent) as PSP,
	abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'Marketing',@WinlostDate),0) as Marketing,
	AffID,
	abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'Odds Fee',@WinlostDate),0) as MemOddsFee,
	 -(-Winlost
	  - ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent))* isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'PSP',@WinlostDate),0)
	  -  abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'Marketing',@WinlostDate),0)
	  - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'Odds Fee',@WinlostDate),0)
	  )as MemWinlostFake
	
FROM #Data d with (nolock)
  inner join  @AffExchange e on e.ExchangeID=d.currency
WHERE  Deposit<>0 or			  
	   Withdrawal<>0 or		
	   Bonus<>0 or	
	   Adjustment<>0 or		
	   TurnOver<>0 or	
		DrawGame<>0 or	
		Outstanding<>0 or	
		Winlost<>0         
UNION ALL
SELECT 
	@WinlostDate,
	IBCCustID, 
	@HRID as SportType, --HorseRacing
	Currency,
	0 as Deposit, 
	0 as Withdrawal, 	
	0 as Bonus, 
	0 as Adjustment, 
	TurnoverHR, 
	OutstandingHR,
	WinlostHR,
	AffExRate,
	MemberExRate,	
	DrawGameHR,
	0 as PSP,
	0 as Marketing,
	AffID,
	0 as MemOddsFee,
	WinlostHR as MemWinlostFake
FROM #Data
WHERE  TurnOverHR<>0 or		
		DrawGameHR<>0 or		
		OutstandingHR<>0 or		
		WinlostHR<>0
--select * from MemberDaily where WinlostDate=@winlostdate

drop table #Data

--Update table AffDaily.

DELETE FROM AffDaily WHERE AffID=@AffID and winlostdate = @winlostdate and SportID in (@SportsBookID, @HRID)

Insert into AffDaily([AffID]
		   ,[Currency]
		   ,[Winlostdate]
		   ,[SportID]
		   ,[ExRate2]
		   ,[MemDeposit]
		   ,[MemWithdrawal]
		   ,[MemTurnover]
		   ,[MemBonus]
		   ,[MemAdjustment]
		   ,[MemMarketing]
		   ,[MemPSP]
		   ,[MemWinlost]
		   ,[AffWinlost]
		   ,[HouseWinlost]
		   ,[AffNetWinlost]
		   ,[HouseNetWinlost]
		   ,[MemWinlostFake]
		   ,[MemOddsFee])

select      d.AffID as AffID,      
			d.Currency as Currency,       
			d.Winlostdate as Winlostdate,       
			d.SportType as SportID,      
			d.AffExRate as Exrate2,       
			SUM(isnull(d.Deposit, 0)) as MemDeposit,   
			SUM(isnull(d.Withdrawal,0)) as MemWithdrawal,       
			SUM(isnull(d.Turnover, 0)) as MemTurnover,       
			SUM(isnull(d.Bonus, 0)) as MemBonus,    
			SUM(isnull(d.Adjustment,0)) as MemAdjustment,    
			0 as MemMarketing,    
			SUM(isnull(d.PSP,0)) as MemPSP,        
			SUM(isnull(d.Winlost, 0)) as MemWinLost,        
			0 as AffWinLost,      
			-SUM(d.Winlost) as HouseWinLost,        
			0 as AffNetWinlost,      
			0 as HouseNetWinLost,	
			0 as MemWinlostFake,      
			0 as MemOddsFee
		from MemberDaily d with (nolock) 
		where AffID=@AffID and d.WinlostDate =@winlostdate and SportType in (@SportsBookID, @HRID)
		GROUP BY d.AffID,d.Winlostdate, d.Currency, d.SportType,d.AffExRate   
  
update AffDaily with (rowlock,updlock)

set [MemMarketing]= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0),
	MemOddsFee= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0),  
	HouseNetWinLost=HouseWinLost
					- isnull(MemBonus,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Bonus',Winlostdate),0)   
					-isnull(MemAdjustment,0)
					-isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',Winlostdate),0)
					- abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)
					- abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0),
	MemWinlostFake=-(-isnull(MemWinlost,0)
					 -isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',Winlostdate),0)		
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)		
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0)
					)
where AffID=@AffID and WinlostDate =@winlostdate and SportID in (@SportsBookID, @HRID)

DELETE FROM AffDailySummary 
WHERE AffID=@AffID and WinlostDate = @winlostdate and SportID in (@SportsBookID, @HRID)

INSERT INTO [dbo].[AffDailySummary]
		   ([AffID]
		   ,[Winlostdate]
		   ,[SportID]
		   ,[MemDeposit]
		   ,[MemWithdrawal]
		   ,[MemTurnover]
		   ,[MemBonus]
		   ,[MemAdjustment]
		   ,[MemMarketing]
		   ,[MemPSP]
		   ,[MemWinlost]
		   ,[AffWinlost]
		   ,[HouseWinlost]
		   ,[AffNetWinlost]
		   ,[HouseNetWinlost]
		   ,[MemOddsFee]
		   ,[MemWinlostFake])

select      [AffID]
		   ,[Winlostdate]
		   ,[SportID]
		   ,sum([MemDeposit]* ExRate2) as MemDeposit
		   ,sum([MemWithdrawal]*ExRate2) as MemWithdrawal
		   ,sum([MemTurnover]*ExRate2) as MemTurnover
		   ,sum([MemBonus]*ExRate2) as MemBonus
		   ,sum([MemAdjustment] * ExRate2) as MemAdjustment
		   ,0 as MemMarketing	
		   ,sum([MemPSP] * ExRate2) as MemPSP
		   ,sum([MemWinlost] * ExRate2) as MemWinlost
		   ,sum([AffWinlost] * ExRate2) as AffWinlost
		   ,sum([HouseWinlost] * ExRate2) as HouseWinlost
		   ,sum([AffNetWinlost]*ExRate2) as AffNetWinlost
		   ,sum([HouseNetWinlost]*ExRate2) as HouseNetWinlost
		   ,0 as MemOddsFee
		   ,0 as MemWinlostFake

from AffDaily(nolock)
where AffID=@AffID and WinlostDate = @winlostdate and SportID in (@SportsBookID, @HRID)
group by AffID,Winlostdate,SportID

update AffDailySummary with (rowlock,updlock)
set MemOddsFee=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate),
	MemMarketing=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate),         
	MemWinlostFake=  -(-MemWinlost
					 - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate)
					 - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate)
					 - MemPSP * dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',WinlostDate)) ,    
   
	 HouseNetWinlost=(
						-MemWinlost
						-MemBonus * dbo.Aff_GetDeductionPercent(AffID,SportID,'Bonus',WinlostDate)
						-MemAdjustment
						-MemPSP * dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate)
					 )
			
	 
  where AffID=@AffID and WinlostDate = @winlostdate  and SportID in (@SportsBookID, @HRID)
  
/*update last MemWinlostFake of last transaction date for each acount
	For example: Affiliate 1 : last day =28/11
				Affiliate 2 : last day= 29/11
				Affiliate 3 : last day= 31/11								
 */


declare @temp table(affid int,SportID int,totalWinlost money, playTechFeePercent float,marketingPercent float,WLFake money,maxWinlostDate smalldatetime,previousMaxWinlostDate smalldatetime,firstday smallDateTime)

insert into @temp(Affid,maxWinlostDate,SportID)
select affid,max(winlostdate),sportid
from AffDailySummary (nolock)
where datediff(m,@winlostdate,WinlostDate)=0  and sportid in (@SportsBookID,@HRID) and AffID=@AffId
  
group by affid,SportID,month(winlostdate),year(winlostdate)

update t
set t.previousMaxWinlostDate=isnull((select max(winlostdate) from AffDailySummary (nolock) where AffID=@AffId  and sportid=t.SportID and winlostdate<t.maxWinlostDate and datediff(m,winlostdate,t.maxWinlostDate)=0),t.maxWinlostDate)
   ,t.firstday=[dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate)    
   ,t.playTechFeePercent=dbo.Aff_GetDeductionPercent(AffID,t.SportID,'PlayTech Royalties',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))
   ,marketingPercent=dbo.Aff_GetDeductionPercent(AffID,t.SportID,'Marketing',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))

from @temp t

--reupdate WinlostFake of previousMaxWinlostDate for MemberDaily, AffDaily, AffDailySummary

update ad

set ad.MemWinlostFake=-(-isnull(ad.MemWinlost,0)
					 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.SportID,'PlayTech Royalties',ad.Winlostdate),0)
					 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.SportID,'Marketing',ad.Winlostdate),0)							 
					)
from AffDailySummary ad with (rowlock,updlock)						
	inner join @temp t on t.affid=ad.AffID and t.previousMaxWinlostDate=ad.WinlostDate and t.SportID=ad.SportID

where ad.AffID=@AffId
	


update d

set d.totalWinlost=isnull(c.totalwinlost,0)
   ,d.WLFake=isnull(c.memWinlostFake,0)
from @temp d
  left join
   ( select t.affid,t.SportID,sum(ad.memwinlost) totalwinlost,sum(ad.memWinlostFake) memWinlostFake
	  from AffDailySummary ad (nolock) 
			inner join @temp t on t.AffID=ad.AffID and t.SportID=ad.SportID
	  where ad.WinlostDate between t.firstday and  t.previousMaxWinlostDate
			and ad.SportID in  (@SportsBookID,@HRID)
			and ad.AffID=@AffId
	  group by t.Affid,t.SportID   
  ) c on c.AffID=d.AffID  and c.SportID=d.SportID 




--select * from @temp

update d
	Set MemWinlostFake=-(-(d1.totalwinlost + d.memwinlost) - abs (d1.totalwinlost + d.memwinlost) * (d1.playTechFeePercent+d1.marketingPercent))- d1.WLFake
from AffDailySummary d with (rowlock,updlock)
	 inner join @temp d1 on d1.affid=d.affid and  d1.maxWinlostDate=d.winlostdate and d1.SportID=d.SportID 			 
where d.sportid in  (@SportsBookID,@HRID) and d.AffID=@AffId





GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailySummaryForAff] TO [vnteam]