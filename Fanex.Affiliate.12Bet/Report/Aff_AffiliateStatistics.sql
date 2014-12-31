ALTER PROCEDURE [dbo].[Aff_AffiliateStatistics]
	@Fromdate 			datetime
	,@Todate 			datetime
	,@IsGetAll 			bit				= 0
	,@UserName 			nvarchar(50)	= NULL
	,@PreferredLanguage	varchar(11) 	= NULL
	,@PageSize 			int				= 50
	,@PageIndex 		int				= 1
	,@SortBy			TINYINT			= 1
	,@NRows 			int				= 0 OUTPUT
AS
/*
Created: @VinhTrinh
Task : Get report by date for all affiliate.
DB: DB052.Affiliate_12BET
Original: [Aff_CustomerSelDetailsByAff]
Revisions:
    - 20141114@Bobby: 
		+ Add sorting [@SortBy] value
		+ Remove @TotalPages
	- 20141223@Bobby: Hotfix#28059 - Filtering by PreferredLanguage
	
Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
	• @UserName Affiliate username need to search(must match username),
	• @PageSize Page Size,
	• @PageIndex Current page,
	• @NRows num rows return
	• @SortBy: Default(0) - AffId ASC, 1 - Total registered desc
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @AffList 
	AS TABLE (
		AffId		INT
		, UserName	VARCHAR(30)
	)

	CREATE TABLE #AffTotal 
	(
		AffId		INT
		, Total		INT
		, RowIDX	INT
	)

	SELECT @UserName = '%' + COALESCE(@UserName, '') + '%'

	SELECT @ToDate = DATEADD(s, - 60, DATEADD(d, DATEDIFF(d, 0, @ToDate) + 1, 0))

	--count nrows
	
	INSERT INTO @AffList( AffId, UserName )
	SELECT md.AffiliateId AS AffID
		, ai.UserName

	FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK) 
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON md.AffiliateId = ai.AffId
		
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) 
		ON ai.AffId = ad.AffId

	WHERE (@IsGetAll = 1 OR (md.CreatDate >= @FromDate AND md.CreatDate < DATEADD(D, 1,@ToDate)))
		AND md.AffiliateId > 0
		AND ai.ApprovedDate <= @ToDate 
		AND ai.STATUS	= 'Approved'
		AND ai.Username LIKE @UserName
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage)
		
		
	GROUP BY md.AffiliateId
		, ai.UserName
	
	HAVING COUNT(1) > 0
	
	SELECT @NRows = COUNT(1) FROM @AffList

	IF (@NRows = 0) RETURN
	
	IF( @SortBy = 1)
	BEGIN
		INSERT INTO #AffTotal
		SELECT AffId
			, Total
			, RowIDX
		FROM (
			SELECT m.AffId
				,ISNULL(dep.Signups, 0) AS Total
				,ROW_NUMBER() OVER ( 
					ORDER BY ISNULL(dep.Signups, 0) DESC
				) AS RowIDX
			FROM @AffList m
				LEFT JOIN (
					SELECT m.AffID
						,COUNT(1) AS Signups
					FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
						INNER JOIN @AffList m
						ON md.AffiliateId = m.AffId
					WHERE (@IsGetAll = 1 OR (md.CreatDate >= @FromDate AND md.CreatDate < DATEADD(D, 1,@ToDate)))
						AND md.AffiliateId > 0
						
					GROUP BY m.AffID
					
					HAVING COUNT(1) > 0
				) dep
				ON m.AffId = dep.AffID
		) t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	END
	ELSE
	BEGIN
		INSERT INTO #AffTotal
		SELECT AffId
			, Total
			, RowIDX
		FROM (
			SELECT m.AffId
				,0 AS Total
				,ROW_NUMBER() OVER ( 
					ORDER BY m.AffId ASC
				) AS RowIDX
			FROM @AffList m
				
		) t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
		
		-- update total SignUp
		UPDATE d
		SET d.Total = ISNULL(dep.Signups, 0)
		FROM #AffTotal d
		LEFT JOIN (
			SELECT m.AffID
				,COUNT(1) AS Signups
			FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
				INNER JOIN #AffTotal m
				ON md.AffiliateId = m.AffId
			WHERE (@IsGetAll = 1 OR (md.CreatDate >= @FromDate AND md.CreatDate < DATEADD(D, 1,@ToDate)))
				AND md.AffiliateId > 0
				
			GROUP BY m.AffID
		) dep
		ON d.AffId = dep.AffId
	END

	;WITH DepositMember(AffId, IBCCustID)
	AS (
		SELECT mi.AffId, IBCCustID
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN #AffTotal m
			ON mi.AffID = m.AffId
		WHERE mi.AffId > 0
			AND mi.IBCCustID > 0
			AND (@IsGetAll = 1 OR mi.CreatedDate BETWEEN @Fromdate AND @Todate)

	)
	, ActiveMember(AffId, Total)
	AS (
		SELECT md.AffId
			,COUNT(DISTINCT md.IBCCustID) AS Total

		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN DepositMember rm
			ON md.AffID = rm.AffId 
				AND md.IBCCustID = rm.IBCCustID
		WHERE md.Turnover > 0 OR md.Deposit > 0
			AND (@IsGetAll = 1 OR md.WinlostDate BETWEEN @Fromdate AND @Todate)

		GROUP BY md.AffId
	)
	-- sum total
	SELECT at.AffId
		,m.Username
		,ISNULL(am.Total, 0) AS Active
		,ISNULL(at.Total, 0) AS Total
		,at.RowIDX

	FROM #AffTotal at

		INNER JOIN @AffList m
		ON at.AffId = m.AffId

		LEFT JOIN ActiveMember am
		ON m.AffId = am.AffId

		ORDER BY at.RowIDX

	DROP TABLE #AffTotal

	RETURN
END
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatistics] TO [bodbAdminNet]
GO

/*
declare @p8 int
declare @p9 int
EXEC Aff_AffiliateStatistics_xtest @Fromdate = '2014-12-01'
	,@Todate = '2014-12-31'
	,@IsGetAll = 0
	,@UserName = N''
	,@PreferredLanguage = 'En-Us'
	,@PageSize = 20
	,@PageIndex = 1
	,@SortBy = 0
	,@NRows = @p9 OUTPUT

select @p8, @p9
go*/