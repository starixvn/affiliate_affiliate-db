ALTER Procedure [dbo].[AffAdmin_ClickStatisticsDetail]  
	@AffID int,  
	@Domain nvarchar(300) = null,
	@SportCode varchar(50) = null,
	@LanguageCode varchar(10) = null,
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
	-20131230:Bobby: change to ClickStatistics & ClickStatistics_bk
	-20140327:Bobby: fixbug https://redmine.nexcel.vn/issues/13595
*/  
BEGIN

	SET NOCOUNT ON  

	Declare @LastDateSum smalldatetime
	if(@FromDate > @ToDate)
		return

	Declare @Result as table(UrlReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)

	select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)
			, @FromDate = convert(varchar(10), @FromDate,120)

	select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))
	
	if (@LastDateSum < @FromDate)--get from main table
	Begin
		insert into @Result
		select 	URLReferrer,
				sum(ClickCount) as TotalClick,
				count(distinct IP) as UniqueClick
				,
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
		from ClickStatistics c
		left join MemberInfo m with (nolock) 
			on c.ClickId = m.ClickId
		where [Date] between @FromDate and @ToDate
				and c.AffId = @AffID
				and SportCode = isnull(@SportCode, SportCode)
				and LanguageCode = isnull(@LanguageCode, LanguageCode)
				and DomainReferrer = isnull(@Domain, DomainReferrer)
		group by URLReferrer
	End
	else if (@LastDateSum > @ToDate)--get from summary table
	Begin
		insert into @Result
		select 	URLReferrer,
				sum(ClickCount) as TotalClick,
				count(distinct IP) as UniqueClick
				,
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
		from ClickStatistics_bk c
		left join MemberInfo m with (nolock) 
			on c.ClickId = m.ClickId
		where [Date] between @FromDate and @ToDate
				and c.AffId = @AffID
				and SportCode = isnull(@SportCode, SportCode)
				and LanguageCode = isnull(@LanguageCode, LanguageCode)
				and DomainReferrer = isnull(@Domain, DomainReferrer)
		group by URLReferrer
	End
	else--@fromdate < @LastDateSum < @ToDate
	Begin
		insert into @Result
		select URLReferrer
			,SUM(TotalClick) TotalClick
			,SUM(UniqueClick) UniqueClick
			,SUM(Signups) Signups
			,SUM(FDM) FDM
		from (
			select 	URLReferrer,
					sum(ClickCount) as TotalClick,
					count(distinct IP) as UniqueClick
					,
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from ClickStatistics c
			left join MemberInfo m with (nolock) 
				on c.ClickId = m.ClickId
			where [Date] between @FromDate and @ToDate
					and c.AffId = @AffID
					and SportCode = isnull(@SportCode, SportCode)
					and LanguageCode = isnull(@LanguageCode, LanguageCode)
					and DomainReferrer = isnull(@Domain, DomainReferrer)
			group by URLReferrer
			union
			select 	URLReferrer,
					sum(ClickCount) as TotalClick,
					count(distinct IP) as UniqueClick
					,
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from ClickStatistics_bk c
			left join MemberInfo m with (nolock) 
				on c.ClickId = m.ClickId
			where [Date] between @FromDate and @ToDate
					and c.AffId = @AffID
					and SportCode = isnull(@SportCode, SportCode)
					and LanguageCode = isnull(@LanguageCode, LanguageCode)
					and DomainReferrer = isnull(@Domain, DomainReferrer)
			group by URLReferrer
		) u
		group by URLReferrer

	End

	--count nrows
	select @NRows=count(1)
	FROM @Result

	if(isnull(@NRows,0)=0)
	   return
   
	DECLARE @RowStart int, @RowEnd int	

	SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
		   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

	SELECT URLReferrer
			, TotalClick
			, UniqueClick
			, Signups
			, FDM
	FROM(       
		SELECT TOP(@RowEnd) 
				ROW_NUMBER() OVER(ORDER BY URLReferrer) AS TheCount,
				*
		FROM @Result
		   ) x
	 where x.TheCount between @RowStart and @RowEnd


 END

 go
 GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsDetail] TO [bodbAdminNet]