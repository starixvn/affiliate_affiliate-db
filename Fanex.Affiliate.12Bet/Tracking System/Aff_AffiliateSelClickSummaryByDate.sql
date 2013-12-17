ALTER PROCEDURE [Aff_AffiliateSelClickSummaryByDate]
	@AffID int,
	@FromDate smalldatetime,	
	@ToDate smalldatetime,	
	@TotalUniqueClicks int OUTPUT,
	@TotalClicks int OUTPUT
AS

/*Created: 20090516@Peter
Task : Get Tracking statistics for affiliate
DB: DB052.Affiliate_12BET
Original : 
Revisions:
	
Param's Explanation:
• @AffID : Affiliate custid
• @FromDate : Date search
• @ToDate : Date search
• @TotalUniqueClicks int OUTPUT,--total of unique clicks(different IPs) for this month
• @TotalClicks int OUTPUT, --total of clicks for this month
*/
--Tracking Statistics
SET NOCOUNT ON

if(@FromDate > @ToDate)
	return

Declare @MaxSumDate smalldatetime, @TmpTodate smalldatetime

select @MaxSumDate = MAX(date) from ClickStatisticsSum nolock

select @TmpTodate = (case when @ToDate > @MaxSumDate then @MaxSumDate else @ToDate end)

Select @TotalClicks=Sum(isnull(TotalClick, 0)),
	@TotalUniqueClicks=Sum(isnull(UniqueClick, 0))
From
	(
	select sum(1) as TotalClick,
			count(distinct s.IP) as UniqueClick
	from ClickStatistics s (nolock)
		inner join TrackingCode a (nolock)  on a.TrackingID=s.TrackingID and a.AffID=@AffID
	where s.date between @FromDate and @ToDate

	Union all

	select TotalClick,
			UniqueClick
	from ClickStatisticsSum (nolock)
	where AffID=@AffID
		and TrackingID=0
		and IsForMonth=0
		and date between @FromDate and @TmpTodate
	) as tmp

	
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickSummaryByDate] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickSummaryByDate] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickSummaryByDate] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelClickSummaryByDate] TO [VNTeam]