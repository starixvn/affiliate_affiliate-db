ALTER Procedure [dbo].[Aff_GetMemberStatistics]
	@AffType tinyint = 0,
	@DepositAll money= 0 Output,
	@DepositMonth money= 0 Output,
	@PSPFeeAll money= 0 Output,
	@PSPFeeMonth money= 0 Output,
	@WinlostAll money= 0 Output,
	@WinlostMonth money= 0 Output,
	@BonusAll money= 0 Output,
	@BonusMonth money= 0 Output,
	@AdjustmentAll money= 0 Output,
	@AdjustmentMonth money= 0 Output,
	@NetWinlostAll money= 0 Output,
	@NetWinlostMonth money= 0 Output
AS

/*
Created: @
Task : Get member statistic
DB: DB052.Affiliate_12BET
Original: 
Revisions:
	- 20101228@Henry: change bettype to new range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120606@Peter : Exclude waiting tickets
Param's Explanation:

*/

SET NOCOUNT ON

declare @MaxWinLostDateAffComm smalldatetime,@NextMaxWinlostDate smalldatetime
declare @CurrentDate smalldatetime, @PreviousDate smalldatetime

select @MaxWinLostDateAffComm=max(winlostdate) from  AffCommission with(nolock)
Select @NextMaxWinlostDate=dateadd(d, 1, @MaxWinLostDateAffComm)
	,@CurrentDate=convert(varchar(10),current_timestamp,120)
	,@PreviousDate=dateadd(d, -1, @CurrentDate)

declare @TblStatistics as table(deposit money, winlost money, bonus money, psp money, Adjustment money, WinlostDate smalldatetime)

Insert into @TblStatistics(deposit, winlost, bonus, psp, Adjustment, winlostdate)		
	select 
		sum(isnull(MemberDeposit, 0)) as deposit,
		sum((isnull(MemberWinlost, 0))) as winlost,
		sum(isnull(MemberBonus, 0)) as bonus,
		sum(isnull(MemberPSP, 0)) as psp,
		sum(isnull(MemberAdjustment, 0)) as Adjustment,
		@MaxWinLostDateAffComm as winlostdate		
	from AffCommission ac with (nolock)
		inner join AffInfo ai with (nolock) on ac.AffId = ai.AffId and ai.AffType = @AffType
	where ai.AffID>0 and SportID>0 and winlostdate<@MaxWinLostDateAffComm
	union all
	select 
		sum(isnull(MemDeposit, 0)*ExRate2) as deposit,
		sum((isnull(MemWinlost, 0))*ExRate2) as winlost,
		sum(isnull(MemBonus, 0)*ExRate2) as bonus,
		sum(isnull(MemPSP, 0)*ExRate2) as psp,
		sum(isnull(MemAdjustment, 0)*ExRate2) as Adjustment,
		dateadd(mm, DATEDIFF(m,0,md.Winlostdate), 0) as winlostdate
	from AffDaily md with (nolock)
		inner join AffInfo ai with(nolock) on md.AffId = ai.AffId and ai.AffType = @AffType
	where Winlostdate between @NextMaxWinlostDate  and @PreviousDate
	group by dateadd(mm, DATEDIFF(m,0,md.winlostdate), 0)
	union all		
	select 	
			sum(case when bettype= 22001 then (isnull(winlost,0)-isnull(abs(actual_stake),0))* m.ActualRate2  else 0 end) as Deposit,
			sum(case when bettype < 19000 then (isnull(winlost,0)-isnull(abs(actual_stake),0)+isnull(playercomm,0)) * m.ActualRate2  else 0 end) as Winlost,
			sum(case when bettype=22004 then (isnull(winlost,0)-isnull(abs(actual_stake),0)) * m.ActualRate2  else 0 end) as Bonus,			
			
			sum(case when bettype= 22001 then (isnull(winlost,0)-isnull(abs(actual_stake),0))* m.ActualRate2  else 0 end) * m.DepositPercent
			+abs(-sum(case when bettype in (22002,22003) then (isnull(winlost,0)-isnull(abs(actual_stake),0))* m.ActualRate2  else 0 end)) * m.WithdrawalPercent
			 as psp,
			sum(case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then (isnull(winlost,0)-isnull(abs(actual_stake),0)) * m.ActualRate2 else 0 end) as Adjustment,
			@CurrentDate as winlostdate				
		from bodb02.dbo.bettrans b with (nolock)	
			inner join (
				 select m.IBCCustID, m.Currency, ActualRate2,e.DepositPercent,e.WithdrawalPercent
				 from MemberInfo m with (nolock) 
					inner join  Exchange_Current e with (nolock)  on e.ExchangeID=m.Currency
					inner join AffInfo ai with(nolock) on m.AffId = ai.AffId and ai.AffType = @AffType
				 where m.IsRemoved=0
			  )m on b.CustId = m.IBCCustID			
		where b.winlostdate = @CurrentDate
			  and ruben=1
			  and (bettype <19000 or bettype in (22001,21001, 21002, 21003, 21004, 21005, 22005,22004,22002,22003))
			 and bettype not between 71 and 120 --Not include Casino and Number Game
			  and StatusID not in (101, 102, 103, 121,1) 
		 group by   m.DepositPercent, m.WithdrawalPercent  
			  
	SELECT		
		@DepositAll =  SUM(isnull(Deposit,0)),
		@WinlostAll = SUM(isnull(Winlost,0)),
		@BonusAll = SUM(isnull(Bonus,0)),
		@PSPFeeAll = SUM(isnull(PSP,0)),
		@AdjustmentAll = SUM(isnull(Adjustment,0)),
		@DepositMonth =SUM(case when datediff(mm, @CurrentDate, winlostdate)=0  then isnull(Deposit,0) else 0 end),
		@WinlostMonth = SUM(case when datediff(mm, @CurrentDate, winlostdate)=0 then isnull(Winlost,0) else 0 end),
		@BonusMonth = SUM(case when datediff(mm, @CurrentDate, winlostdate)=0 then isnull(Bonus,0) else 0 end),
		@PSPFeeMonth = SUM(case when datediff(mm, @CurrentDate, winlostdate)=0 then isnull(PSP,0) else 0 end),
		@AdjustmentMonth = SUM(case when datediff(mm, @CurrentDate, winlostdate)=0 then isnull(Adjustment,0) else 0 end) 
	FROM @TblStatistics 	
	
	
	
	SELECT @NetWinlostAll = isnull(@WinlostAll,0) + isnull(@BonusAll,0) + isnull(@AdjustmentAll,0),
		   @NetWinlostMonth = isnull(@WinlostMonth,0) + isnull(@BonusMonth,0) + isnull(@AdjustmentMonth,0)
		   
	
	
GO
GRANT EXECUTE ON [dbo].[Aff_GetMemberStatistics] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetMemberStatistics] TO [vnteam]

