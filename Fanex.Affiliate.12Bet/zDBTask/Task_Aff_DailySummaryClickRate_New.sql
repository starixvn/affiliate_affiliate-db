ALTER PROCEDURE [dbo].[Task_Aff_DailySummaryClickRate_New]
	@date smalldatetime = null
AS
/*
	Created: 20120109@Johnny
	Task:	Task to summary Click Statistics daily
	DB: DBAFF12BET/Affiliate_12BET
	Revisions:	
		- @20140214: optimize performance (to use index)
	
*/
BEGIN
	SET NOCOUNT ON


	select @date = convert(varchar(10), ISNULL(@date, dateAdd(d, -30, current_timestamp)), 120)

	if(exists (select 1 from ClickStatistics1Sum (nolock) where @date = [Date]))
	begin
	   return
	end 

	/* 
	--Store Total number of deposit user
	Declare @TmpDeposit as table(AffId int, TotalDeposit int)
	insert into @TmpDeposit(AffId, TotalDeposit)
	Select AffId, Sum(1) as TotalDeposit
	From MemberInfo nolock
	where datediff(d, CreatedDate, @date) = 0
	Group by AffId 
	 */

	 --Summary for Daily by Domain and Date
	insert into ClickStatistics1Sum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
	select  AffID,
			DomainReferrer,
			@date as [Date],
			SportCode,
			LanguageCode,
			sum(1) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(case when status > 0 then 1 else 0 end) as TotalSignup,
			SUM(case when status = 2 then 1 else 0 end) as  TotalDeposit
	from ClickStatistics1 (nolock)
	where @date = [Date] --datediff(d, @date, [date])=0
	group by AffID, DomainReferrer, SportCode, LanguageCode


	insert into ClickStatistics1_bk (
			[ClickID]
			,[AffID]
			,[UpdatedTime]
			,[IP]
			,[Date]
			,[Browser]
			,[URLReferrer]
			,[DomainReferrer]
			,[OS]
			,[Device]
			,[BrowserVersion]
			,[BrowserResolution]
			,[BrowserLanguage]
			,[UserAgent]
			,[Country]
			,[LanguageCode]
			,[SportCode]
			,[RedirectURL]
			,[Status])
	select 
			[ClickID]
			,[AffID]
			,[UpdatedTime]
			,[IP]
			,[Date]
			,[Browser]
			,[URLReferrer]
			,[DomainReferrer]
			,[OS]
			,[Device]
			,[BrowserVersion]
			,[BrowserResolution]
			,[BrowserLanguage]
			,[UserAgent]
			,[Country]
			,[LanguageCode]
			,[SportCode]
			,[RedirectURL]
			,[Status]
	from ClickStatistics1
	where @date = [Date]-- datediff(d, @date, [date])=0

	delete ClickStatistics1
	where @date = [Date] -- datediff(d, @date, [date])=0

END


GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_DailySummaryClickRate_New] TO [vnteam]