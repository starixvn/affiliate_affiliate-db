ALTER PROCEDURE [dbo].[Aff_ActiveMemberReport] 
	@Fromdate 				DATETIME 		=	NULL
	,@Todate 				DATETIME 		= NULL
	,@IsGetAll 				BIT 			= 0
	,@UserName 				NVARCHAR(50) 	= NULL
	,@PreferredLanguage 	VARCHAR(11) 	= NULL
	,@AffType 				TINYINT 		= NULL
	,@PageSize 				INT 			= 50
	,@PageIndex 			INT 			= 1
	,@SortBy				TINYINT 		= 0
	,@NRows 				INT 			= 0 OUTPUT
AS
/*
Created: @Peter
Task : Get report of Active members 
DB: DB052.Affiliate_12BET
Original: [Aff_ActiveMemberReport]
Revisions:
	- Remove TrackingCode table when inner join with ClickstatisticsSum table 
	- 20141114@Bobby: 
		+ Add sorting [@SortBy] value
		+ Remove @TotalPages
		
Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
	• @UserName Affiliate username need to search(must match username),
	• @PageSize Page Size,
	• @PageIndex Current page,
	• @TotalPages num pages return,
	• @NRows num rows return
	• @SortBy: Default(0) - AffId ASC, 1 - Total Signup DESC
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CurrMonth	DATETIME
		,@CurrDate		DATETIME

	DECLARE @AffList 
	AS TABLE (
		AffId		INT
		, UserName	VARCHAR(30)
		, IsClosed	BIT
	)
	CREATE TABLE #AffTotal(
		AffId		INT
		, Signup	INT
		, FDM		INT
		, RowIDX	INT
		, NRows		INT
	)
	
	SELECT @UserName = '%' + Coalesce(@UserName, '') + '%'

	SELECT @ToDate		= dateadd(s, - 60, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))
		, @CurrDate		= GETDATE()
		, @CurrMonth	= DATEADD(M, DATEDIFF(M, 0, @CurrDate), 0)

	--count nrows
	
	INSERT INTO @AffList( AffId, UserName, IsClosed )
	SELECT ai.AffID
		, ai.UserName
		, ai.IsClosed
		
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) 
		ON ai.AffId = ad.AffId
	WHERE ai.STATUS = 'Approved'
		AND ai.Username LIKE @UserName
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage) 
		AND (@AffType IS NULL OR ai.AffType = @AffType)
		AND (
			@IsGetAll = 1
			OR ai.ApprovedDate <= @Todate
		)
	
	IF (@@ROWCOUNT = 0) RETURN
	
	-- Check IsAll row
	SELECT @PageSize = CASE 
						WHEN @IsGetAll = 1 THEN @NRows 
						ELSE @PageSize 
					END
		,@PageIndex = CASE 
						WHEN @IsGetAll = 1 THEN 1 
						ELSE @PageIndex 
					END
	
	;WITH MemberStats (AffId, Signup, FDM)
	AS (
		SELECT AffId
			,SUM(Signups)
			,SUM(FDMs)
		FROM (
			SELECT md.AffID
				,0 AS Signups
				,COUNT(1) AS FDMs
			FROM dbo.MemberInfo md WITH (NOLOCK)
				INNER JOIN @AffList m
				ON md.AffID = m.AffId
			WHERE (@IsGetAll = 1 OR md.CreatedDate BETWEEN @FromDate AND @ToDate)
				AND md.IBCCustId NOT IN (
					SELECT IBCCustId
					FROM dbo.MemberRemoval WITH (NOLOCK)
					WHERE RemovedDate BETWEEN @FromDate AND @ToDate
					)
			GROUP BY md.AffID
			
			UNION ALL
			SELECT m.AffID
				,COUNT(1) AS Signups
				,0 AS FDMs
			FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
				INNER JOIN @AffList m
				ON md.AffiliateId = m.AffId
			WHERE (@IsGetAll = 1 OR (md.CreatDate >= @FromDate AND md.CreatDate < DATEADD(D, 1,@ToDate)))
				AND md.AffiliateId > 0
				
			GROUP BY m.AffID
		) AS t
		GROUP BY t.AffID
		HAVING SUM(Signups) > 0
			OR SUM(FDMs)	> 0

	)
	INSERT INTO #AffTotal(AffId, Signup, FDM, RowIDX, NRows)
	SELECT AffId, Signup, FDM, RowIDX, NRows
	FROM (
		SELECT m.AffId
			,ISNULL(ms.Signup, 0) 	AS Signup
			,ISNULL(ms.FDM, 0)		AS FDM
			,ROW_NUMBER() OVER ( 
						ORDER BY m.IsClosed ASC
								,CASE WHEN @SortBy = 1 THEN ISNULL(ms.Signup, 0) ELSE 0 END DESC
								,CASE WHEN @SortBy = 0 THEN m.AffId ELSE 0 END ASC
					) AS RowIDX
			,r.NRows
		FROM @AffList m
			INNER JOIN MemberStats ms 
			ON m.AffId = ms.AffId
			
			CROSS APPLY (
				SELECT COUNT(1) AS NRows 
				FROM MemberStats
			) r
	) t
	WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY t.RowIDX
	
	SELECT TOP 1 @NRows = NRows FROM #AffTotal
	
	;WITH OldTracking (AffId, TotalClick, UniqueClick) 
	AS (
		SELECT t.AffId 
			, SUM(t.TotalClick)	
			, SUM(t.UniqueClick)
		FROM (
			SELECT t1.AffId 
				, SUM(t1.TotalClick)	AS TotalClick
				, SUM(t1.UniqueClick)	AS UniqueClick
			FROM (
					SELECT a.AffId
						,[DATE]
						,COUNT(1) TotalClick
						,COUNT(DISTINCT s.IP) AS UniqueClick
					FROM dbo.ClickStatistics s(NOLOCK)
						INNER JOIN dbo.TrackingCode a(NOLOCK) 
						ON a.TrackingID = s.TrackingID
						INNER JOIN #AffTotal m
						ON a.AffID = m.AffId
					WHERE s.DATE >= @CurrMonth
						AND s.IP <> ''
						AND [Date] BETWEEN @CurrMonth AND @ToDate
					GROUP BY a.AffId
						,[DATE]
			) t1

			GROUP BY t1.AffID

			UNION ALL
			SELECT s.AffId
				,SUM(TotalClick)
				,SUM(UniqueClick)
			FROM dbo.ClickStatisticsSum s(NOLOCK)
			INNER JOIN #AffTotal m
				ON s.AffID = m.AffId
			WHERE TrackingID = 0
				AND IsForMonth = 1
				AND (@IsGetAll = 1 OR [DATE] BETWEEN @FromDate AND @CurrMonth)

			GROUP BY s.AffId
		) t
		GROUP BY t.AffId 

	)
	, NewTracking (AffId, TotalClick, UniqueClick)
	AS (
		SELECT t.AffId 
			, SUM(t.TotalClick)
			, SUM(t.UniqueClick)
		FROM (
			SELECT t1.AffId 
				, SUM(t1.TotalClick) TotalClick
				, SUM(t1.UniqueClick) UniqueClick
			FROM (
				SELECT m.AffId 
					,[Date]
					,SUM(1)					AS TotalClick
					,COUNT(DISTINCT s.IP)	AS UniqueClick
				FROM dbo.ClickStatistics1 s WITH(NOLOCK)
					INNER JOIN #AffTotal m
					ON s.AffID = m.AffId
				WHERE [Date] BETWEEN @FromDate AND @ToDate
				GROUP BY m.AffId 
					,[Date]
			) t1
			GROUP BY t1.AffId 

			UNION ALL
			SELECT m.AffId 
				,SUM(TotalClick)	AS TotalClick
				,SUM(UniqueClick)	AS UniqueClick
			FROM dbo.ClickStatistics1Sum s WITH(NOLOCK)
				INNER JOIN #AffTotal m
				ON s.AffID = m.AffId
			WHERE (@IsGetAll = 1 OR [Date] BETWEEN @FromDate AND @ToDate)
			GROUP BY m.AffId 
		) t
		GROUP BY t.AffId 

	)
	SELECT t.AffId
		,m.UserName
		,m.IsClosed
		,t.Signup
		,t.FDM
		,ISNULL(ot.TotalClick, 0)	AS TotalClicks_Old
		,ISNULL(ot.UniqueClick, 0)	AS UniqueClicks_Old
		,ISNULL(nt.TotalClick, 0) 	AS TotalClicks_New
		,ISNULL(nt.UniqueClick, 0)	AS UniqueClicks_New
		,t.RowIDX
	FROM #AffTotal t
	
		INNER JOIN @AffList m
		ON t.AffId = m.AffId
		
		LEFT JOIN OldTracking ot
		ON t.AffId = ot.AffId
		
		LEFT JOIN NewTracking nt
		ON t.AffId = nt.AffId
		
	ORDER BY t.RowIDX
		
	
	DROP TABLE #AffTotal
	
	SET @NRows = ISNULL(@NRows, 0)

	RETURN
END
GO

GRANT EXECUTE ON [dbo].[Aff_ActiveMemberReport] TO [bodbAdminNet]
GO

declare @p9 int
declare @p10 int
EXEC Aff_ActiveMemberReport @Fromdate = '2014-12-08'
	,@Todate = '2014-12-09'
	,@IsGetAll = 0
	,@UserName = DEFAULT
	,@PreferredLanguage = DEFAULT
	,@AffType = DEFAULT
	,@PageSize = 20
	,@PageIndex = 1
	,@SortBy = 1
	,@NRows = @p10 OUTPUT

select @p9, @p10
go
