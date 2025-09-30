ALTER PROCEDURE [dbo].[Aff_AffiliateSelClickStatisticsMonthDetail]
		@AffID int,
        @month int, 
        @year int,
        @TrackingCode varchar(20)=null--Statistics for all TrackingCode
AS
/*
Created: 20090427@Peter
Task : summary of TotalClick,Unique Click Daily for specific month
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
.@AffID: id of affiliate in the system,
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.

• @ErrMsg: Error description.
*/
 SET NOCOUNT ON
--Select Statistics for all TrackingCode
declare @firstDayOfThisMonth smalldatetime
set @firstDayOfThisMonth=cast(@year as varchar(6)) + '-' + cast(@month as varchar(2)) + '-01'
--Get Data In Affiliate_ClickStatistics
if(datediff(mm,@firstDayOfThisMonth,current_timestamp)=0)
begin
	select Date,sum(1) as TotalClick,count(distinct s.IP) as UniqueClick
   from ClickStatistics s (nolock)
   where trackingid in (
	 select trackingid 
         from TrackingCode (nolock) 
         where AffID=@AffID and TrackingCode=coalesce(@TrackingCode,TrackingCode)
   ) and IP<>'' and datediff(mm,current_timestamp,s.date)=0
   group by s.Date
   order by s.Date desc
end
else --Get Data In Affiliate_ClickStatisticsSum
begin
   --Get Data for all TrackingCode
   if(coalesce(@TrackingCode,'')='')
    begin
        select Date,TotalClick,UniqueClick
        from ClickStatisticsSum s (nolock)
        where  AffID=@AffID 
               and TrackingID=0
               and IsForMonth=0 
               and datediff(mm,@firstDayOfThisMonth,s.date)=0 
         order by Date desc
    end
    else
     begin
		select Date,TotalClick,UniqueClick
        from ClickStatisticsSum s (nolock)
        where AffID=@AffID
           and TrackingID in (
               select trackingid 
               from TrackingCode (nolock) 
               where AffID=@AffID and TrackingCode=@TrackingCode
           )
           and IsForMonth=0
           and datediff(mm,@firstDayOfThisMonth,s.date)=0  
        order by Date desc		
     end 
	
end

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetail] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetail] TO [bodbDownlineNetView]
GO  
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelClickStatisticsMonthDetail] TO [vnteam]
GO