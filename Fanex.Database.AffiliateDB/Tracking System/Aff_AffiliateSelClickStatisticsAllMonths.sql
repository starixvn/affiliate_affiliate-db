ALTER PROCEDURE [dbo].[Aff_AffiliateSelClickStatisticsAllMonths]
		@AffID int,
        @TrackingCode varchar(20)=null--Statistics for all TrackingCode
AS
/*
Created: 20090427@Peter
Task : summary of TotalClick,Unique Click for all month 
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
Declare @CurrMonth smalldatetime

select @CurrMonth = dateadd(m, datediff(m, 0, current_timestamp), 0)

if(coalesce(@TrackingCode,'')='')
begin
 --Select for current month
   select @CurrMonth as Date,
          sum(1) as TotalClick,count(distinct s.IP) as UniqueClick
   from ClickStatistics s (nolock)
   where trackingid in (
	 select trackingid 
         from TrackingCode (nolock) 
         where AffID=@AffID
   ) and IP<>'' and datediff(mm,current_timestamp,s.date)=0
   group by month(s.Date),year(s.Date)          
  --Select for previous month
  select Date,TotalClick,UniqueClick
  from ClickStatisticsSum s (nolock)
  where AffID=@AffID and TrackingID=0 and IsForMonth=1
  order by Date desc
 
 end
else -- Select for specific TrackingCode
  begin
		--Select for current month
	   select @CurrMonth as Date,
			  sum(1) as TotalClick,count(distinct s.IP) as UniqueClick
	   from ClickStatistics s (nolock)
	   where trackingid in (
		 select trackingid 
			 from TrackingCode (nolock) 
			 where AffID=@AffID and TrackingCode=@TrackingCode
	   ) and IP<>'' and datediff(mm,current_timestamp,s.date)=0
	   group by month(s.Date),year(s.Date)          
	  --Select for previous month
	  select Date,TotalClick,UniqueClick
	  from ClickStatisticsSum s (nolock)
	  where AffID=@AffID 
            and TrackingID in (
              select trackingid 
			  from TrackingCode (nolock) 
			  where AffID=@AffID and TrackingCode=@TrackingCode
            )
            and IsForMonth=1
	  order by Date desc 
     
  end
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsAllMonths] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsAllMonths] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelClickStatisticsAllMonths] TO [bodbDownlineNetView]
GO  
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelClickStatisticsAllMonths] TO [vnteam]
GO