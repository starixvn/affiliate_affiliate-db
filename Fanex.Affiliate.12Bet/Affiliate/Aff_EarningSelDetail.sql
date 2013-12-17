ALTER PROCEDURE [dbo].[Aff_EarningSelDetail]
 @AffId int = 0,
 @SportType tinyint = 0,
 @MonthDate smalldatetime 
AS
/*
 Created: 200900911@VinhTrinh
 Task : [description of SP]  
 DB: DB052.Affiliate_12BET
 Revisions:    
        - 20101228@Henry: change bettype to new range
     - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120]) 
     - 20120606@Peter : Exclude waiting tickets 
 Param's Explanation:  
 • @AffId affliate Id  
 • @MonthDate Month date need to view.  
*/  
SET NOCOUNT ON
DECLARE @CurrDate smalldatetime,@SportsBookID int,@HorseRacingID int
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')
SET @CurrDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)

select @MonthDate = dateadd(d, datediff(d, 0, @MonthDate), 0)

if (@SportType <> 3 and @CurrDate = @MonthDate)
Begin--Get current date data for sp and hr in bettrans table
 SELECT 
  b.CustID as CustID,
  m.UserName,
  m.IBCUserName,
  isnull(sum(case when (@SportType = @SportsBookID or @SportType = 0) and bettype = 22001 then (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0) as Deposit,
  -isnull(sum(case when (@SportType = 0 or @SportType = @SportsBookID) and bettype in (22002,22003) then  (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0) as Withdrawal,
  isnull(sum(case 
      when @SportType = 0 and bettype < 999 then (winlost-abs(actual_stake)+playercomm) * e.ActualRate2
   when @SportType = @SportsBookID and bettype < 999  and bettype not in (31,32,33,41,42,43) then (winlost-abs(actual_stake)+playercomm) * e.ActualRate2
   when @SportType = @HorseRacingID and bettype < 999 and bettype in (31,32,33,41,42,43) then (winlost-abs(actual_stake)+playercomm) * e.ActualRate2
   else 0 end)
  ,0) as WinLost,
  isnull(sum(case when bettype < 999 then isnull(abs(stake) * e.ActualRate2,0) else 0 end),0) as Turnover,
  isnull(sum(case when (@SportType = @SportsBookID or @SportType = 0) and bettype = 22004 then (winlost-abs(actual_stake))* e.ActualRate2 else 0 end),0) as Bonus,
  isnull(sum(case when (@SportType = @SportsBookID or @SportType = 0) and bettype in (21001, 21002, 21003, 21004, 21005, 22005) then (winlost-abs(actual_stake))* e.ActualRate2 else 0 end),0) as Adjustment,  
  isnull(sum(case when (@SportType = @SportsBookID or @SportType = 0) and bettype = 22001 then (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0) * e.DepositPercent
  + abs(-isnull(sum(case when (@SportType = 0 or @SportType = @SportsBookID) and bettype in (22002,22003) then  (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0)) * e.WithdrawalPercent
   as PSP,
   e.ActualRate2 as AffExRate
  --sum(isnull(dbo.Aff_GetMemberPSP(m.IBCCustID,@CurrDate, @SportsBookID) * e.ActualRate2,0)) as PSP
 FROM bodb02.dbo.bettrans b with(nolock)
  inner join 
   (select IBCCustID, Currency, UserName, IBCUserName
   from MemberInfo with(nolock) 
   where AffID = @AffID and IsRemoved = 0) m on m.IBCCustID = b.CustId   
  INNER JOIN Exchange_current e WITH (NOLOCK) ON m.Currency = e.Exchangeid 
 WHERE b.Winlostdate = @MonthDate 
       and b.ruben = 1 
       and (bettype<999 or bettype in (22001,22004,21001, 21002, 21003, 21004, 21005, 22005,22002,22003) ) 
    and bettype not between 31 and 120 --Not include Casino and Number Game
    and StatusID not in (101, 102, 103, 121,1) 
   --and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING') 
 GROUP BY b.CustID, m.UserName, m.IBCUserName, e.DepositPercent,e.WithdrawalPercent, e.ActualRate2
End
else
Begin--Currdate for Casino sport just need to get in MemberDaily table
 SELECT 
  m.IBCCustId as CustID,
  m.UserName,
  m.IBCUserName, 
  isnull(Sum(d.Winlost * AffExRate), 0) as winlost,
  isnull(Sum(d.Withdrawal * AffExRate), 0) as Withdrawal,
  isnull(Sum(d.TurnOver * AffExRate), 0) as Turnover,
  isnull(Sum(d.Deposit * AffExRate), 0) as Deposit,
  isnull(Sum(d.Withdrawal * AffExRate), 0) as Withdrawal,
  isnull(Sum(d.Bonus * AffExRate), 0) as Bonus,
  isnull(Sum(d.Adjustment * AffExRate), 0) as Adjustment,
  isnull(Sum(d.PSP * AffExRate), 0) as PSP,
  d.AffExRate
 FROM MemberDaily d with(nolock)
  inner join MemberInfo m with (nolock) on d.IBCCustId = m.IBCCustId
 WHERE d.AffID = @AffID  
  AND d.winlostdate = @MonthDate
  and (case when @SportType = 0 then 1 when @SportType = SportType then 1 else 0 end) = 1
  AND (isnull(d.TurnOver,0) <>0 or isnull(d.Winlost,0)<>0 or isnull(d.Bonus,0)<>0 or isnull(d.Adjustment,0)<>0 or isnull(d.PSP,0)<>0 or isnull(d.Marketing,0)<>0 or isnull(d.Deposit,0)<>0 or isnull(Withdrawal,0)<>0) 
 GROUP BY m.IBCCustId, m.UserName, m.IBCUserName,d.AffExRate
End

GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbDownlineNetView]																
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EarningSelDetail] TO [vnteam]