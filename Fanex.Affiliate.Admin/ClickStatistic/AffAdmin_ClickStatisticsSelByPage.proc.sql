<<<<<<< HEAD
﻿
ALTER Procedure [dbo].[AffAdmin_ClickStatisticsSelByPage]
=======
﻿ALTER Procedure [dbo].[AffAdmin_ClickStatisticsSelByPage]
>>>>>>> de12fc63ca6f25dff8aaff117b461d45d2e16627
	@AffID int,  
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@SportCode varchar(200) = null,
	@LanguageCode varchar(100) = null
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DB052.Affiliate_AoncashUAT
Original:  
  
Revisions:  
-20131230:Bobby: change to ClickStatistics & ClickStatistics_bk
*/  
BEGIN
	SET NOCOUNT ON  

	Declare @LastDateSum smalldatetime
	if(@FromDate > @ToDate)
		return

	DECLARE @SportCodeTable TABLE (SportCode varchar(20))
	INSERT INTO @SportCodeTable
	SELECT CAST(val AS varchar(20)) 
	FROM [dbo].[strSplit] ( @SportCode, ',' )

	DECLARE @LanguageCodeTable TABLE (LanguageCode varchar(20))
	INSERT INTO @LanguageCodeTable
	SELECT CAST(val AS varchar(20))
	FROM [dbo].[strSplit] ( @LanguageCode, ',' )

	Declare @Result as table(SportCode varchar(50), LanguageCode varchar(10), TotalClick int, UniqueClick int, Signups int, FDM int)

	select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)

	select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))
			, @FromDate = convert(varchar(10), @FromDate,120)

	if (@FromDate > @LastDateSum)--get from main table
	Begin
		insert into @Result
		select SportCode,LanguageCode
			, sum(TotalClick) TotalClick
			, sum(UniqueClick) UniqueClick
			, sum(Signups) Signups
			, sum(FDM) FDM
		from (
			select 	URLReferrer,c.SportCode,c.LanguageCode,
					sum(ClickCount) as TotalClick,
					count(distinct IP) as UniqueClick
					,
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from ClickStatistics c
			INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
			INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
			left join MemberInfo m with (nolock) 
				on c.ClickId = m.ClickId
			where [Date] between @FromDate and @ToDate
					and c.AffId = @AffID
			group by URLReferrer,c.SportCode,c.LanguageCode
		) as t
		group by SportCode,LanguageCode
		order by SportCode, LanguageCode
	End
	else if (@ToDate < @LastDateSum)--get from summary table
	Begin
		insert into @Result
		select SportCode,LanguageCode
			, sum(TotalClick) TotalClick
			, sum(UniqueClick) UniqueClick
			, sum(Signups) Signups
			, sum(FDM) FDM
		from (
			select 	URLReferrer,c.SportCode,c.LanguageCode,
					sum(ClickCount) as TotalClick,
					count(distinct IP) as UniqueClick
					,
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from ClickStatistics_bk c
			INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
			INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
			left join MemberInfo m with (nolock) 
				on c.ClickId = m.ClickId
			where [Date] between @FromDate and @ToDate
					and c.AffId = @AffID
			group by URLReferrer,c.SportCode,c.LanguageCode
		) as t
		group by SportCode,LanguageCode
		order by SportCode, LanguageCode
	End
	else--@fromdate < @LastDateSum < @ToDate
	Begin
		insert into @Result
		select SportCode,LanguageCode
			, sum(TotalClick) TotalClick
			, sum(UniqueClick) UniqueClick
			, sum(Signups) Signups
			, sum(FDM) FDM
		from (
			select SportCode,LanguageCode
				, sum(TotalClick) TotalClick
				, sum(UniqueClick) UniqueClick
				, sum(Signups) Signups
				, sum(FDM) FDM
			from (
				select 	URLReferrer,c.SportCode,c.LanguageCode,
						sum(ClickCount) as TotalClick,
						count(distinct IP) as UniqueClick
						,
						SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
						SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from ClickStatistics c
				INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
				INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
				left join MemberInfo m with (nolock) 
					on c.ClickId = m.ClickId
				where [Date] between @FromDate and @ToDate
						and c.AffId = @AffID
				group by URLReferrer,c.SportCode,c.LanguageCode
			) as t
			group by SportCode,LanguageCode
			union
			select SportCode,LanguageCode
				, sum(TotalClick) TotalClick
				, sum(UniqueClick) UniqueClick
				, sum(Signups) Signups
				, sum(FDM) FDM
			from (
				select 	URLReferrer,c.SportCode,c.LanguageCode,
						sum(ClickCount) as TotalClick,
						count(distinct IP) as UniqueClick
						,
						SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
						SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from ClickStatistics_bk c
				INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
				INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
				left join MemberInfo m with (nolock) 
					on c.ClickId = m.ClickId
				where [Date] between @FromDate and @ToDate
						and c.AffId = @AffID
				group by URLReferrer,c.SportCode,c.LanguageCode
			) as t2
			group by SportCode,LanguageCode
		) t3
		group by SportCode,LanguageCode
		order by SportCode,LanguageCode

	End

	SELECT r.*
		, ISNULL(lan.LanguageName,'N/A') AS LanguageName
	FROM @Result AS r
	LEFT JOIN dbo.[Language] AS lan WITH (NOLOCK) 
		ON r.LanguageCode=lan.LanguageID
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [vnteam]