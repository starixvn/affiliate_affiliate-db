ALTER PROCEDURE [dbo].[Task_Aff_DailySummaryClickRate_New] 
	@date SMALLDATETIME = NULL
AS
/*
	Created: 20120109@Johnny
	Task:	Task to summary Click Statistics daily
	DB: DBAFF12BET/Affiliate_12BET
	Revisions:	
		- @20140214: optimize performance (to use index)
		- 20140613@Bobby: Update @date to 7 days (date backup)
	
*/
BEGIN
	SET NOCOUNT ON

	SELECT @date = convert(VARCHAR(10), ISNULL(@date, dateAdd(DD, - 7, current_timestamp)), 120)

	IF (
			EXISTS (
				SELECT 1
				FROM ClickStatistics1Sum(NOLOCK)
				WHERE @date = [Date]
				)
			)
	BEGIN
		RETURN
	END

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
	INSERT INTO ClickStatistics1Sum (
		AffID
		,[DomainReferrer]
		,[Date]
		,[SportCode]
		,[LanguageCode]
		,TotalClick
		,UniqueClick
		,TotalSignup
		,TotalDeposit
		)
	SELECT AffID
		,DomainReferrer
		,@date AS [Date]
		,SportCode
		,LanguageCode
		,sum(1) AS TotalClick
		,count(DISTINCT IP) AS UniqueClick
		,SUM(CASE 
				WHEN STATUS > 0 THEN 1
				ELSE 0
				END) AS TotalSignup
		,SUM(CASE 
				WHEN STATUS = 2 THEN 1
				ELSE 0
				END) AS TotalDeposit
	FROM ClickStatistics1(NOLOCK)
	WHERE @date = [Date] --datediff(d, @date, [date])=0
	GROUP BY AffID
		,DomainReferrer
		,SportCode
		,LanguageCode

	INSERT INTO ClickStatistics1_bk (
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
		)
	SELECT [ClickID]
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
	FROM ClickStatistics1
	WHERE @date = [Date] -- datediff(d, @date, [date])=0

	DELETE ClickStatistics1
	WHERE @date = [Date] -- datediff(d, @date, [date])=0
END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_DailySummaryClickRate_New] TO [vnteam]
