set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Aff_ReportDetailSelByAff]
	@AffID int,
	@Fromdate datetime,
	@Todate datetime,
	@AffType tinyint = 0
AS
/*
Created: @VinhTrinh
Task : Get report by date for all affiliate.
	Three cases to calculate report:
	  + @Todate<=@OldReportDate ---> use old formula
	  + @FromDate>@OldReportDate
	     . @FromDate --> @MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)
	     . @MaxTransDate + 1 --> @Todate-1: use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
	     . @CurDate : from bettrans	 and cannot calculate Affiliate Winlost and House Winlost
      + @FromDate-->@OldReportDate-->@Todate:
         .@FromDate -->@OldReportDate:use old formula
         .@OldReportDate + 1 --->@MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)
         .@MaxTransDate +1 --->@Todate-1 :use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
         . @CurDate : from bettrans	 and cannot calculate Affiliate Winlost and House Winlost 
DB: DB052.Affiliate_ZZun
Original: [Aff_CustomerSelDetailsByAff]
Revisions:
    
Param's Explanation:
	• @Fromdate Month search from
	• @Todate To month.
*/
SET NOCOUNT ON


if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN

declare @CurrDate datetime,@TmpToDate datetime


select @CurrDate =  getdate()
		
		
Select @TmpToDate=@ToDate
if(@Todate>=@CurrDate)
select @TmpToDate=@CurrDate
	
      
Select Winlostdate, 
			at.Name as AffTypeName,
			e.Code as Currency, 
			--e.Currency, 
			a.SysExRate as Actualrate, 
			isnull(Sum(MemDeposit), 0) as Deposit,
			isnull(Sum(MemTurnover), 0) as Turnover,			
			isnull(Sum(MemBonus), 0) as Bonus,
			isnull(Sum(MemWinLost), 0) as MemberWinLost,
			isnull(Sum(AffWinLost), 0) as AffiliateWinLost,
			isnull(Sum(HouseWinLost), 0) as HouseWinLost,
			isnull(Sum(AffNetWinLost), 0) as AffiliateNetWinLost,
			isnull(Sum(HouseNetWinLost), 0) as HouseNetWinLost
		From AffDaily a with(nolock)
			inner join Exchange e with(nolock) on a.MemCurrency = e.ExchangeID
			inner join AffInfo ai with(nolock) on a.AffID = ai.AffID
			 left join AffType at with (nolock) on ai.AffType = at.TypeID
		Where winlostdate between @FromDate and @TmpToDate and a.AffID = @AffId
		and (@AffType = 0 OR ai.AffType = @AffType)
		Group By Winlostdate, e.Code, a.SysExRate,at.Name
		order by Winlostdate,e.Code



GO
GRANT EXECUTE ON [dbo].[Aff_ReportDetailSelByAff] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportDetailSelByAff] TO [VNTeam] 