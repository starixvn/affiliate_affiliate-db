ALTER PROCEDURE [dbo].[AffAdmin_MemberStatisticsReport]
	@UserId int=0, 
	@AffName NVARCHAR(100) = NULL,
	@AffTypes varchar(100) = NULL,
	--@CommGroups varchar(1000) = NULL,
	@PreferLanguages varchar(1000) = NULL,
	@Currencies varchar(100) = NULL,
	@GroupBy tinyint = 0,
	@FromDate smalldatetime = NULL,
	@ToDate smalldatetime = NULL,
	@SortBy tinyint = 0,
	@ExcludeTest bit = 1,
	@IsITAdmin bit = 0
AS
/*    
Task : Player Winloss Report     
DB:    
Original:[[AffAdmin_MemberStatisticsReport]]
Revisions:           
                
Param's Explanation: 
• @UserId: Admin user id
• @AffName: Affiliate username
• @AffTypes: List affilaite type
--• @CommGroups: List Commission group
• @PreferLanguages: list preference language
• @Currencies: List currencies
• @GroupBy: by date or month (0: by All; 1: by Date; 2: By Month)
• @FromDate: From date
• @ToDate: To date
• @SortBy: 
	- 0: Affiliate
	- 1: Sign Up
	- 2: Active
• @ExcludeTest: not include test accounts if true.
• @@IsITAdmin: Is IT Account.
*/    
SET NOCOUNT ON 


Declare @LastDateSum smalldatetime
if(@FromDate > @ToDate)
	return

Declare @AffList as table(AffId int, Username varchar(50), AffType varchar(50), Language nvarchar(255), Currency varchar(5), status varchar(50))

insert INTO @AffList(AffId, Username, AffType, Language, Currency, Status)
Select AffId, Username, AffType, Language, Currency, Status
from [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, null, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 

Declare @Result as table(AffId int, Username varchar(50), DateClick datetime, AffType varchar(50), Language nvarchar(255), Currency varchar(5), status varchar(50)
			, TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)

select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))
		, @FromDate = [dbo].[Aff_GetStartDate](@FromDate)

IF(@GroupBy = 0)--Reset from date from system start and Current date (All data)
Begin
	Select @FromDate = cast((select top(1) SValue from SystemSettings(nolock) where Type='Meta' and SName='SystemStartDate') as smalldatetime )
			, @ToDate = current_timestamp
End


if (@LastDateSum < @FromDate)--get from main table
Begin
	insert into @Result	
	Select 
		t.AffId,
		Username,
		Date,
		AffType,
		Language,
		Currency,
		t.Status,
		sum(ClickCount) as TotalClick,
		count(distinct IP) as UniqueClick,
		SUM(isnull(Signups, 0)) as Signups,
		SUM(isnull(FDM, 0)) as  FDM
	from @AffList as t 
		LEFT JOIN ClickStatistics c with(nolock) on c.AffId = t.AffId and [Date] between @FromDate and @ToDate
		left join 
			(Select ClickId, 
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from MemberInfo m with (nolock) 
			where RegisteredDate between @FromDate and @ToDate--For month that is not sum click
				or CreatedDate between @FromDate and @ToDate
			group by ClickId
			) as m on c.ClickId = m.ClickId	
	group by t.AffId, Username, Date, AffType, Language, Currency, t.Status
	--[Date] in group by to calculate unique click
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
	insert into @Result
	Select 
		t.AffId,
		Username,
		Date,
		AffType,
		Language,
		Currency,
		Status,
		sum(TotalClick) as TotalClick,
		sum(UniqueClick) as UniqueClick,
		sum(TotalSignup) as Signups,
		sum(TotalDeposit) as FDM
	from @AffList as t
		LEFT JOIN ClickStatisticsSum c with(nolock) on c.AffId = t.AffId and [Date] between @FromDate and @ToDate
	group by t.AffId, Username, Date, AffType, Language, Currency, Status
	order by Username, Date
End
else--@fromdate < @LastDateSum < @ToDate
Begin
	insert into @Result
	select	AffId,
			Username,
			Date,
			AffType,
			Language,
			Currency,
			Status,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			t.AffId,
			Username,
			Date,
			AffType,
			Language,
			Currency,
			t.Status,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(TotalSignup) as Signups,
			sum(TotalDeposit) as FDM
		from @AffList as t
			LEFT JOIN ClickStatisticsSum c with(nolock) on c.AffId = t.AffId and [Date] between @FromDate and @LastDateSum
		group by t.AffId, Username, Date, AffType, Language, Currency, t.Status

		Union All

		Select 
			t.AffId,
			Username,
			Date,
			AffType,
			Language,
			Currency,
			t.Status,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from @AffList as t
			LEFT JOIN ClickStatistics c with(nolock) on c.AffId = t.AffId AND [Date] between @FromDate and @ToDate
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where RegisteredDate between @FromDate and @ToDate--For month that is not sum click
						or CreatedDate between @FromDate and @ToDate
				group by ClickId
				) as m on c.ClickId = m.ClickId
		group by t.AffId, Username, Date, AffType, Language, Currency, t.Status
		) tmp
	group by AffId, Username, Date, AffType, Language, Currency, Status
End


IF (@GroupBy = 0)-- By All (Affiliate)
Begin
	Select	r.AffId,
			Username,
			AffType,
			Language,
			Currency,
			Status,
			Sum(TotalClick) as TotalClick,
			Sum(UniqueClick) as UniqueClick,
			Sum(Signups) as Signups,
			Sum(FDM) as FDM,
			Sum(Signups - FDM) as NonDeposit,
			Sum(isnull(tmp.ActivePlayers, 0)) as ActivePlayers
	From @Result as r
		LEFT JOIN 
			(SELECT AffId, COUNT(DISTINCT UserName) as ActivePlayers
			From MemberDaily WITH (NOLOCK) 
			where Turnover > 0
			GROUP  by AffID
			) as tmp on r.AffId = tmp.AffId
	Group BY r.AffId, Username, AffType, Language, Currency, Status
	Having Sum(TotalClick) > 0 OR
			Sum(UniqueClick) > 0 OR
			Sum(Signups) > 0 OR
			Sum(FDM) > 0 OR
			Sum(Signups - FDM) > 0 OR
			Sum(isnull(tmp.ActivePlayers, 0)) > 0
	order BY 
			(CASE 
				WHEN @SortBy = 1 THEN Sum(Signups)
				WHEN @SortBy = 2 THEN Sum(tmp.ActivePlayers)
			END) desc, r.AffId
End
ELSE IF (@GroupBy = 1)-- By Date
Begin
	Select	r.AffId,
			Username,
			isnull(r.DateClick, tmp.Winlostdate) as DateClick,
			AffType,
			Language,
			Currency,
			Status,
			isnull(TotalClick, 0) as TotalClick,
			isnull(UniqueClick, 0) as UniqueClick,
			isnull(Signups, 0) as Signups,
			isnull(FDM, 0) as FDM,
			isnull((Signups - FDM), 0) as NonDeposit,
			isnull(tmp.ActivePlayers, 0) as ActivePlayers
	From @Result as r
		LEFT JOIN 
			(SELECT AffID, COUNT(DISTINCT UserName) as ActivePlayers, WinlostDate
			From MemberDaily WITH (NOLOCK) 
			where Winlostdate between @FromDate and @ToDate
				AND Turnover > 0
			GROUP  by AffID, Winlostdate
			) as tmp on r.AffId = tmp.AffId and (r.DateClick = tmp.Winlostdate OR r.DateClick IS NULL OR tmp.WinlostDate IS NULL)
	Where TotalClick > 0 or
			UniqueClick > 0 OR
			Signups > 0 OR
			FDM > 0 OR
			tmp.ActivePlayers > 0
	order BY 
			(CASE 
				WHEN @SortBy = 1 THEN Signups
				WHEN @SortBy = 2 THEN tmp.ActivePlayers
			END) desc,
			(CASE 
				WHEN @SortBy = 3 THEN r.AffId
			END), 
			(CASE 
				WHEN r.DateClick IS NULL THEN tmp.WinlostDate
				ELSE r.DateClick
			END) Desc, r.Username
End
ELSE IF (@GroupBy = 2)-- By Month
Begin
	Select r.AffId,
			Username,
			isnull(r.DateClick, tmp.WinlostDate) as DateClick,
			AffType,
			Language,
			Currency,
			Status,
			isnull(TotalClick, 0) as TotalClick,
			isnull(UniqueClick, 0) as UniqueClick,
			isnull(Signups, 0) as Signups,
			isnull(FDM, 0) as FDM,
			isnull((Signups - FDM), 0) as NonDeposit,
			isnull(tmp.ActivePlayers, 0) as ActivePlayers
	From
		(
		Select	r.AffId,
				Username,
				dateadd(m, datediff(m, 0, r.DateClick), 0) as DateClick,
				AffType,
				Language,
				Currency,
				Status,
				Sum(TotalClick) as TotalClick,
				Sum(UniqueClick) as UniqueClick,
				Sum(Signups) as Signups,
				Sum(FDM) as FDM,
				Sum(Signups - FDM) as NonDeposit
		From @Result as r
		Group By r.AffId, Username, dateadd(m, datediff(m, 0, r.DateClick), 0), AffType, Language, Currency, Status
		) as r
		LEFT JOIN
		(SELECT AffID
			, COUNT(DISTINCT UserName) as ActivePlayers
			, dateadd(m, datediff(m, 0, Winlostdate), 0) as WinlostDate					
		From MemberDaily WITH (NOLOCK) 
		where Winlostdate between @FromDate and @ToDate
			AND Turnover > 0
		GROUP  by AffID, dateadd(m, datediff(m, 0, Winlostdate), 0)
		) as tmp on r.AffId = tmp.AffId and (datediff(m, r.DateClick, tmp.Winlostdate) = 0 OR r.DateClick IS NULL OR tmp.WinlostDate IS NULL)
	Where TotalClick > 0 or
			UniqueClick > 0 OR
			Signups > 0 OR
			FDM > 0 OR
			tmp.ActivePlayers > 0
	order BY 
			(CASE 
				WHEN @SortBy = 1 THEN Signups
				WHEN @SortBy = 2 THEN tmp.ActivePlayers
			END) desc,
			(CASE 
				WHEN @SortBy = 3 THEN r.AffId
			END), 
			(CASE 
				WHEN r.DateClick IS NULL THEN tmp.WinlostDate
				ELSE r.DateClick
			END) Desc, r.Username
End

GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberStatisticsReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_MemberStatisticsReport] TO [vnteam] AS [dbo]