ALTER PROCEDURE [dbo].[Task_Aff_DailySummaryClickRate] 
	@date SMALLDATETIME = NULL
AS
/*
	Created by: 20120109@Johnny	
	Task:  Task to summary Click Statistics daily 
	DB: DBAFFAthena000/Affiliate_Athena000
	Orginal SP:
	Revisions:
		20140213@Dan: optimize to use index (not use date function)
*/
BEGIN
	SET NOCOUNT ON

	SELECT @date = CONVERT(VARCHAR(10), ISNULL(@date, DATEADD(d, - 30, CURRENT_TIMESTAMP)), 120)

	IF (
			EXISTS (
				SELECT 1
				FROM ClickStatisticsSum WITH (NOLOCK)
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
	INSERT INTO ClickStatisticsSum (
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
	SELECT c.AffID
		,DomainReferrer
		,@date AS [Date]
		,SportCode
		,LanguageCode
		,sum(ClickCount) AS TotalClick
		,count(DISTINCT IP) AS UniqueClick
		,SUM(isnull(Signups, 0)) AS Signups
		,SUM(isnull(FDM, 0)) AS FDM
	FROM ClickStatistics c WITH (NOLOCK)
		LEFT JOIN (
		SELECT ClickId
			,SUM(CASE 
					WHEN m.RegisteredDate IS NOT NULL THEN 1
					ELSE 0
					END) AS Signups
			,SUM(CASE 
					WHEN m.CreatedDate IS NOT NULL THEN 1
					ELSE 0
					END) AS FDM
		FROM MemberInfo m WITH (NOLOCK)
		GROUP BY ClickId
		) AS m
		ON c.ClickId = m.ClickId
	WHERE @date = [date]
	GROUP BY c.AffID
		,DomainReferrer
		,SportCode
		,LanguageCode
	OPTION (RECOMPILE)

	INSERT INTO ClickStatistics_bk (
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
		,[ClickCount]
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
		,[ClickCount]
	FROM ClickStatistics WITH (NOLOCK)
	WHERE @date = [date] --datediff(d, @date, [date])=0

	DELETE ClickStatistics
	WHERE @date = [date] --datediff(d, @date, [date])=0
END
