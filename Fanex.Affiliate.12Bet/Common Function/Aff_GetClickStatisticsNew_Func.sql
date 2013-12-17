CREATE FUNCTION [dbo].[Aff_GetClickStatisticsNew_Func]
(
	@AffId int, 
	@FromDate smalldatetime,
	@ToDate smalldatetime
)
RETURNS @Result TABLE 
(
	TotalClicks int, 
	UniqueClicks int
)
AS
BEGIN
	
	INSERT @Result
	select 
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick
	from 
		(
		Select 			
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick
		from ClickStatistics1Sum with(nolock) 
		where [Date] between @FromDate and @ToDate
			and AffId = @AffID

		Union All

		Select 
			sum(1) as TotalClick,
			count(distinct IP) as UniqueClick
		from ClickStatistics1 with(nolock) 
		where [Date] between @FromDate and @ToDate
			and AffId = @AffID
		group by  [Date]
		) tmp

	RETURN 
END