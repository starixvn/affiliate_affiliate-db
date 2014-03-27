ALTER Procedure [dbo].[AffAdmin_ClickStatisticsSelBySite]    
	@AffID int,    
	@FromDate smalldatetime,  
	@ToDate smalldatetime,  
	@TotalClicks int = 0 output,  
	@UniqueClicks int = 0 output  
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
  
	Declare @Result as table(DomainReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)  
  
	select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)  
  
	select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))  
		, @FromDate = convert(varchar(10), @FromDate,120)  
  
	if (@LastDateSum < @FromDate)--get from main table  
	BEGIN  
		INSERT INTO @Result  
		SELECT   
			DomainReferrer,  
			sum(ClickCount) as TotalClick,  
			count(distinct IP) as UniqueClick  
			,
			SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
			SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
		FROM dbo.ClickStatistics c with(nolock)   
		LEFT JOIN MemberInfo m with (nolock) 
				on c.ClickId = m.ClickId
		WHERE c.[Date] between @FromDate and @ToDate  
			and c.AffId = @AffID  
		GROUP BY DomainReferrer
	END  
	ELSE IF (@LastDateSum > @ToDate)--get from summary table  
	Begin  
		INSERT INTO @Result  
		SELECT   
			DomainReferrer,  
			sum(ClickCount) as TotalClick,  
			count(distinct IP) as UniqueClick  
			,
			SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
			SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
		FROM dbo.ClickStatistics_bk c with(nolock)   
		LEFT JOIN MemberInfo m with (nolock) 
				on c.ClickId = m.ClickId
		WHERE c.[Date] between @FromDate and @ToDate  
			and c.AffId = @AffID  
		GROUP BY DomainReferrer
	END  
	ELSE--@fromdate < @LastDateSum < @ToDate  
	BEGIN  
		INSERT INTO @Result  
		SELECT T.DomainReferrer
			, SUM(TotalClick) AS TotalClick
			, SUM(UniqueClick) AS UniqueClick
			, SUM(Signups) AS Signups
			, SUM(FDM) AS FDM
		FROM (
			SELECT   
				DomainReferrer,  
				sum(ClickCount) as TotalClick,  
				count(distinct IP) as UniqueClick  
				,
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			FROM dbo.ClickStatistics c with(nolock)   
			LEFT JOIN MemberInfo m with (nolock) 
					on c.ClickId = m.ClickId
			WHERE c.[Date] between @FromDate and @ToDate  
				and c.AffId = @AffID  
			GROUP BY DomainReferrer
			UNION ALL
			SELECT   
				DomainReferrer,  
				sum(ClickCount) as TotalClick,  
				count(distinct IP) as UniqueClick  
				,
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			FROM dbo.ClickStatistics_bk c with(nolock)   
			LEFT JOIN MemberInfo m with (nolock) 
					on c.ClickId = m.ClickId
			WHERE c.[Date] between @FromDate and @ToDate  
				and c.AffId = @AffID  
			GROUP BY DomainReferrer
		) AS T
		GROUP BY DomainReferrer 
  
	END  
	
	SELECT @TotalClicks = SUM(TotalClick)  
		, @UniqueClicks = SUM(UniqueClick)  
	FROM @Result

	SELECT * FROM @Result  
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [bodbAdminNet]
