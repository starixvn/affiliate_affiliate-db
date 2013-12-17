ALTER FUNCTION [dbo].[Aff_MemberDailyForCurrentDate]
(
	@AffID int
	
)
RETURNS @MemberDaily TABLE(IBCCustID int,SportID int,Deposit money,Winlost money,Bonus money, Adjustment money,PSP money, Marketing money, TurnOver money)  
As

begin

Declare  @Today smalldatetime,@SportsBookID int,@HorseRacingID int

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')

--Get last day of inputted month
Select @Today = convert (varchar(12),current_timestamp)

insert into @MemberDaily(IBCCustID,SportID,Deposit,Winlost,Bonus, Adjustment,PSP, Marketing,TurnOver)  
 select *

from
(

select
		  ci.IBCCustID, 					
					case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end as SportType,	
					isnull(sum(case bettype when 22001 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end) * e.Actualrate2,0) as Deposit,				
					isnull(sum(case when bettype < 19000 AND ruben = 1 then (b.Winlost -abs(b.actual_stake)) else 0 end) * e.Actualrate2, 0) as Winlost, 					
					isnull(sum(case bettype when 22004 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end) * e.Actualrate2,0) as Bonus,
					isnull(sum(case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end) * e.Actualrate2,0) as Adjustment,				
					isnull(sum(case bettype when 22001 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end) * e.Actualrate2,0) * e.DepositPercent
					+  abs(-isnull(sum(case when bettype in (22002,22003) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end) * e.Actualrate2,0)*e.WithdrawalPercent)
							as PSP,
					0 as Marketing,
					isnull(sum(case when bettype < 19000 then 
								(case when Bettype in (33,43) and liveawayscore = 0 then isnull(abs(stake), 0) / 2 * e.Actualrate2 else isnull(abs(stake), 0) end)
							else 0 end) * e.Actualrate2,0) as Turnover
				from MemberInfo ci with (nolock)
					inner join bodb02.dbo.bettrans b with (nolock) on b.custid = ci.IBCCustID 
					INNER JOIN Exchange_Current e with (nolock)  on e.exchangeid=ci.currency  
				where b.winlostdate=@Today  
				   and b.recommend= ci.recommend                     
					and ci.AffID=@AffID
					and ci.IsRemoved = 0
					AND (Bettype < 19000  or bettype in (22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005))		
					 and bettype not between 71 and 120 --Not include Casino and Number Game
					and StatusID not in (101, 102, 103, 121,1)
					--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')	
				Group by ci.IBCCustID, case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end,e.Actualrate2,e.DepositPercent,e.WithdrawalPercent


union all 

select IBCCustID,SportType,isnull(Deposit*AffExRate,0),isnull(Winlost*AffExRate,0),isnull(Bonus*AffExRate,0),isnull(Adjustment*AffExRate,0),
		isnull(PSP*AffExRate,0),isnull(Marketing*AffExRate,0),isnull(TurnOver*AffExRate,0)
from MemberDaily (nolock)
where winlostdate=@Today and SportType not in (@SportsBookID,@HorseRacingID) and AffID=@AffID


) t


return
end
