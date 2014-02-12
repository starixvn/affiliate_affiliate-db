ALTER PROCEDURE [Aff_AffiliateSelClickStatisticsMonthDetailAll]
	@AffID int,
	@MonthDate smalldatetime,	
	@TotalUniqueClicks int OUTPUT,
	@TotalClicks int OUTPUT
AS

/*Created: 20090516@Peter
Task : Get Tracking statistics for affiliate
DB: DB052.Affiliate_ZZun
Original : 
Revisions:
	
Param's Explanation:
• @AffID : Affiliate custid
• @MonthDate : Date search(format:first day of the month).
• @TotalUniqueClicks int OUTPUT,--total of unique clicks(different IPs) for this month
• @TotalClicks int OUTPUT, --total of clicks for this month
*/
--Tracking Statistics
SET NOCOUNT ON
if(datediff(mm,@MonthDate,current_timestamp)=0)
begin
	select @TotalClicks=sum(1),@TotalUniqueClicks=count(distinct s.IP)
	from ClickStatistics s (nolock)
	 inner join TrackingCode a (nolock)  on a.TrackingID=s.TrackingID and a.AffID=@AffID
	where datediff(mm,@MonthDate,s.date)=0 
	--group by a.AffiliateID,month(s.Date),year(s.Date)
end
else
begin
	select @TotalClicks=TotalClick,@TotalUniqueClicks=UniqueClick
	from ClickStatisticsSum (nolock)
	where AffID=@AffID
               and TrackingID=0
               and IsForMonth=1 
               and datediff(mm,@MonthDate,[date])=0
end

	
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetailAll] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetailAll] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetailAll] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetailAll] TO [VNTeam]



