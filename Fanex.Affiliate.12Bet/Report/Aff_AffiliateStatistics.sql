/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

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
	- 20170214@Percy: Fix FDM/Signup Issue [RedmineID: #70507]
	
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
		;WITH memberStats AS (
			SELECT md.AffID, COUNT(1) AS Signups
			FROM dbo.MemberClickDetail md WITH (NOLOCK)
			WHERE (@IsGetAll = 1 OR md.CreatedDate BETWEEN @FromDate AND @ToDate)
				AND EXISTS (SELECT 1 FROM @AffList a WHERE md.AffID = a.AffId)
			GROUP BY md.AffID

			UNION ALL
			SELECT md.AffiliateId AS AffID, COUNT(1) AS Signups
			FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
			WHERE (@IsGetAll = 1 OR md.CreatDate BETWEEN @FromDate AND @ToDate)
				AND EXISTS (SELECT 1 FROM @AffList a WHERE a.AffId = md.AffiliateId)
			GROUP BY md.AffiliateId
		)
		INSERT INTO #AffTotal
		SELECT AffId
			, Total
			, RowIDX
		FROM (
			SELECT m.AffId
				,ISNULL(dep.Signups, 0) AS Total
				,ROW_NUMBER() OVER (ORDER BY ISNULL(dep.Signups, 0) DESC) AS RowIDX
			FROM @AffList m
				LEFT JOIN (
					SELECT AffID, MAX(Signups) AS Signups FROM memberStats GROUP BY AffID
				) dep ON m.AffId = dep.AffID
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
				,ROW_NUMBER() OVER (ORDER BY m.AffId ASC) AS RowIDX
			FROM @AffList m
				
		) t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
		
		-- update total SignUp
		;WITH memberStats AS (
			SELECT md.AffID, COUNT(1) AS Signups
			FROM dbo.MemberClickDetail md WITH (NOLOCK)
			WHERE (@IsGetAll = 1 OR md.CreatedDate BETWEEN @FromDate AND @ToDate)
				AND EXISTS (SELECT 1 FROM @AffList a WHERE md.AffID = a.AffId)
			GROUP BY md.AffID

			UNION ALL
			SELECT md.AffiliateId AS AffID, COUNT(1) AS Signups
			FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
			WHERE (@IsGetAll = 1 OR md.CreatDate BETWEEN @FromDate AND @ToDate)
				AND EXISTS (SELECT 1 FROM @AffList a WHERE a.AffId = md.AffiliateId)
			GROUP BY md.AffiliateId
		)
		UPDATE d
		SET d.Total = ISNULL(dep.Signups, 0)
		FROM #AffTotal d
			LEFT JOIN (
					SELECT AffID, MAX(Signups) AS Signups FROM memberStats GROUP BY AffID
				) dep ON d.AffId = dep.AffID
	END

	;WITH DepositMember(AffId, IBCCustID)
	AS (
		SELECT mi.AffId, IBCCustID
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN #AffTotal m ON mi.AffID = m.AffId
		WHERE mi.AffId > 0
			AND mi.IBCCustID > 0
			AND (@IsGetAll = 1 OR mi.CreatedDate BETWEEN @Fromdate AND @Todate)

	)
	, ActiveMember(AffId, Total)
	AS (
		SELECT
			mi.AffId,
			COUNT(mi.IBCCustID) AS Total
		FROM dbo.MemberInfo mi WITH (NOLOCK)
		WHERE
			(
				@IsGetAll = 1
				OR (mi.CreatedDate BETWEEN @FromDate AND @ToDate)
			)
			AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = mi.AffId)
			AND
			(
				@IsGetAll = 1
				OR NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE
						mr.IBCCustID = mi.IBCCustID
						AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
				)
			)
		GROUP BY mi.AffId

		UNION ALL
		SELECT
			md.AffiliateId AS AffId,
			COUNT(md.IBCCustID) AS Total
		FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
		WHERE
			(
				@IsGetAll = 1
				OR (md.CreatDate BETWEEN @FromDate AND @ToDate)
			)
			AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = md.AffiliateId)
		GROUP BY md.AffiliateId
	)
	-- sum total
	SELECT at.AffId
		,m.Username
		,ISNULL(am.Total, 0) AS Active
		,ISNULL(at.Total, 0) AS Total
		,at.RowIDX

	FROM #AffTotal at
		INNER JOIN @AffList m ON at.AffId = m.AffId
		LEFT JOIN (SELECT AffId, MAX(Total) AS Total FROM ActiveMember GROUP BY AffId) AS am ON m.AffId = am.AffId
	ORDER BY at.RowIDX

	DROP TABLE #AffTotal
END
GO