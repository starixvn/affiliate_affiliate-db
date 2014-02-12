set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER Procedure [dbo].[Aff_AffiliateReportDetail]
	@AffUsername varchar(50),
	@AffId int = 0 OUTPUT,
	@AffCurrency varchar(5) = 'MYR' OUTPUT,
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit = 0
AS
/*
	DB052.Affiliate_ZZun
*/

if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN

select @AffId = AffId,
	@AffCurrency = e.Code
from AffInfo ai with(nolock) 
	inner join Exchange e with(nolock) on ai.Currency = e.ExchangeID
where Username = @AffUsername

if @AffId = 0 --Invalid AffUsername
	return
	
Declare @CurrDate datetime, @TmpToDate datetime

select @CurrDate =  dbo.Aff_GetEndDate(current_timestamp),
		@Fromdate = dbo.Aff_GetStartDate(@Fromdate),
		@Todate = dbo.Aff_GetEndDate(@Todate)
		

if @IsGetAll = 1
Begin
	select @FromDate = min(WinlostDate) from AffDailySummary with (nolock)
	select @ToDate = dbo.Aff_GetEndDate(current_timestamp)
	
	select @TmpToDate =@CurrDate--To date for new way calculate winlost
End
Else
Begin
	select @TmpToDate = case when @ToDate >= @CurrDate then @CurrDate else @ToDate end
End


select WinlostDate,
	b.AffExRate,
	e.Code as Currency,
	Sum(b.Deposit) as Deposit,
	Sum(b.Withdrawal) as Withdrawal,
	Sum(b.Turnover) as Turnover,
	Sum(b.Winlost) as Winlost,
	Sum(b.Bonus) as Bonus,
	Sum(b.PSP) as PSP,
	Sum(b.Adjustment) as Adjustment,
	Sum(b.AffAdjustment) as AffAdjustment,
	Sum(b.AffWithdrawal) as AffWithdrawal,
	Sum(b.AffBF) as AffBF
From 
	(	
		Select WinlostDate,--Calculate winlost member below Aff in MemberDaily and AffCommission table
			MemCurrency as Currency,
			AffExRate as AffExRate,--convert exchange rate from member to system currency
			Sum(MemDeposit) as Deposit,
			Sum(MemWithdrawal) as Withdrawal,
			Sum(MemTurnover) as Turnover,
			Sum(MemWinlost) as Winlost,
			Sum(MemBonus) as Bonus,
			Sum(MemPSP) as PSP,
			Sum(MemAdjustment) as Adjustment,
			0 as AffAdjustment,
			0 as AffWithdrawal,
			sum(AffNetWinlost) as AffBF
		From AffDaily with(nolock)
		Where WinlostDate Between @FromDate and @TmpToDate
			and AffId = @AffId
		Group by WinlostDate, MemCurrency, AffExRate		
		
		Union All
		
		select dateadd(d, datediff(d, 0, a.TransDate), 0) as WinlostDate,--Get Aff Adjusment and Aff Widthrawal
			a.AffCurrency as Currency,--Currency of aff
			1 as AffExRate,--convert exchange rate from affiliate to system currency
			0 as Deposit,
			0 as Withdrawal,
			0 as Turnover,
			0 as Winlost,
			0 as Bonus,
			0 as PSP,
			0 as Adjustment,
			Sum(case when Transtype = 203 then Amount else 0 end) as AffAdjustment,
			Sum(case when Transtype = 202 then Amount else 0 end) as AffWithdrawal,
			0 as AffBF
		From AffTrans a with (nolock)
		where (@IsGetAll = 1 or TransDate between @FromDate and @ToDate)
			and Transtype in (202, 203)
			and status in ('Pending', 'Approved', 'Completed')
			and a.AffId = @AffId
		Group by dateadd(d, datediff(d, 0, a.TransDate), 0), a.AffCurrency, SysExRate
	) b 
   inner join Exchange e (nolock) on e.ExchangeID=b.Currency
Group by WinlostDate, b.AffExRate,e.Code 
order by WinlostDate

GO


GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateReportDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateReportDetail] TO [VNTeam] 