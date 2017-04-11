/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Aff_AffiliateStatistics]
	@Fromdate 			datetime
	,@Todate 			datetime
	,@IsGetAll 			bit				= 0
	,@UserName 			nvarchar(60)	= NULL
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

	SELECT @UserName = '%' + COALESCE(@UserName, '') + '%'

	SELECT @ToDate = DATEADD(SECOND, -1, DATEADD(DAY, DATEDIFF(DAY, 0, @ToDate) + 1, 0))

	DECLARE @AffList TABLE
	(
		AffId		INT,
		UserName	VARCHAR(60)
	)

	INSERT INTO @AffList (AffId, UserName)
	SELECT md.AffiliateId AS AffID, ai.UserName
	FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK) 
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON md.AffiliateId = ai.AffId
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE (@IsGetAll = 1 OR (md.CreatDate >= @FromDate AND md.CreatDate < DATEADD(D, 1,@ToDate)))
		AND md.AffiliateId > 0
		AND ai.ApprovedDate <= @ToDate 
		AND ai.STATUS	= 'Approved'
		AND ai.Username LIKE @UserName
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage)
	GROUP BY md.AffiliateId, ai.UserName
	HAVING COUNT(1) > 0
	
	SELECT @NRows = COUNT(1) FROM @AffList

	IF ISNULL(@NRows, 0) = 0
		RETURN

	CREATE TABLE #AffTotal 
	(
		AffId		INT,
		UserName	VARCHAR(60),
		Active		INT,
		Dormant		INT,
		FDMs		INT,
		Signups		INT,
		RowIDX		INT
	)
	
	IF @SortBy = 1 -- sort by Total Registered
	BEGIN
		;WITH memberStats AS (
			SELECT AffID, SUM(ISNULL(Signups, 0)) AS Signups, SUM(ISNULL(FDMs, 0)) AS FDMs
			FROM (
				SELECT md.AffID, COUNT(1) AS Signups, 0 AS FDMs
				FROM dbo.MemberClickDetail md WITH (NOLOCK)
				WHERE (@IsGetAll = 1 OR md.CreatedDate BETWEEN @FromDate AND @ToDate)
					AND EXISTS (SELECT 1 FROM @AffList a WHERE md.AffID = a.AffId)
				GROUP BY md.AffID

				UNION ALL
				SELECT mi.AffID, 0 AS Signups, COUNT(mi.IBCCustID) AS FDMs
				FROM dbo.MemberInfo mi WITH (NOLOCK)
				WHERE (@IsGetAll = 1 OR mi.CreatedDate BETWEEN @FromDate AND @ToDate)
					AND EXISTS (SELECT 1 FROM @AffList a WHERE mi.AffID = a.AffId)
					AND
					(
						(@IsGetAll = 1 AND mi.IsRemoved = 0)
						OR NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE
								mr.IBCCustID = mi.IBCCustID
								AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
						)
					)
				GROUP BY mi.AffID
			) AS A
			GROUP BY AffID

			UNION ALL
			SELECT md.AffiliateId AS AffID, COUNT(1) AS Signups, COUNT(IBCCustID) AS FDMs
			FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
			WHERE (@IsGetAll = 1 OR md.CreatDate BETWEEN @FromDate AND @ToDate)
				AND EXISTS (SELECT 1 FROM @AffList a WHERE a.AffId = md.AffiliateId)
			GROUP BY md.AffiliateId
		)

		INSERT INTO #AffTotal (AffId, UserName, FDMs, Signups, RowIDX)
		SELECT AffId, UserName, FDMs, Signups, RowIDX
		FROM
		(
			SELECT
				m.AffId, m.UserName, ISNULL(dep.FDMs, 0) AS FDMs, ISNULL(dep.Signups, 0) AS Signups,
				ROW_NUMBER() OVER (ORDER BY ISNULL(dep.Signups, 0) DESC) AS RowIDX
			FROM @AffList m
				LEFT JOIN (
					SELECT AffID, MAX(FDMs) AS FDMs, MAX(Signups) AS Signups FROM memberStats GROUP BY AffID
				) dep ON m.AffId = dep.AffID
		) AS t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	END
	ELSE -- @SortBy = 0 -- sort by AffiliateID
	BEGIN
		INSERT INTO #AffTotal (AffId, UserName, FDMs, Signups, RowIDX)
		SELECT AffId, UserName, FDMs, Signups, RowIDX
		FROM (
			SELECT
				m.AffId, m.UserName, 0 AS FDMs, 0 AS Signups,
				ROW_NUMBER() OVER (ORDER BY m.AffId ASC) AS RowIDX
			FROM @AffList m
		) AS t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
		
		-- update total SignUp
		;WITH memberStats AS (
			SELECT AffID, SUM(ISNULL(Signups, 0)) AS Signups, SUM(ISNULL(FDMs, 0)) AS FDMs
			FROM (
				SELECT md.AffID, COUNT(1) AS Signups, 0 AS FDMs
				FROM dbo.MemberClickDetail md WITH (NOLOCK)
				WHERE (@IsGetAll = 1 OR md.CreatedDate BETWEEN @FromDate AND @ToDate)
					AND EXISTS (SELECT 1 FROM #AffTotal a WHERE md.AffID = a.AffId)
				GROUP BY md.AffID

				UNION ALL
				SELECT mi.AffID, 0 AS Signups, COUNT(mi.IBCCustID) AS FDMs
				FROM dbo.MemberInfo mi WITH (NOLOCK)
				WHERE (@IsGetAll = 1 OR mi.CreatedDate BETWEEN @FromDate AND @ToDate)
					AND EXISTS (SELECT 1 FROM #AffTotal a WHERE mi.AffID = a.AffId)
					AND
					(
						(@IsGetAll = 1 AND mi.IsRemoved = 0)
						OR NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE
								mr.IBCCustID = mi.IBCCustID
								AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
						)
					)
				GROUP BY mi.AffID
			) AS A
			GROUP BY AffID

			UNION ALL
			SELECT md.AffiliateId AS AffID, COUNT(1) AS Signups, COUNT(IBCCustID) AS FDMs
			FROM [DBDeposit].deposit_db.dbo.Deposit_Customer md WITH (NOLOCK)
			WHERE (@IsGetAll = 1 OR md.CreatDate BETWEEN @FromDate AND @ToDate)
				AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = md.AffiliateId)
			GROUP BY md.AffiliateId
		)
		UPDATE d
		SET
			d.FDMs = ISNULL(dep.FDMs, 0),
			d.Signups = ISNULL(dep.Signups, 0)
		FROM #AffTotal d
			LEFT JOIN (
					SELECT AffID, MAX(FDMs) AS FDMs, MAX(Signups) AS Signups FROM memberStats GROUP BY AffID
				) dep ON d.AffId = dep.AffID
	END

	;WITH ActiveMember AS
	(
		SELECT md.AffID, COUNT(DISTINCT md.IBCCustID) AS Active
		FROM dbo.MemberDaily md WITH(NOLOCK)
		WHERE (@IsGetAll = 1 OR md.WinlostDate BETWEEN @FromDate AND @ToDate)
			AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = md.AffID)
			AND EXISTS (
				SELECT 1
				FROM dbo.MemberInfo mi WITH (NOLOCK)
				WHERE (@IsGetAll = 1 OR mi.CreatedDate BETWEEN @FromDate AND @ToDate)
					AND EXISTS (SELECT 1 FROM #AffTotal a WHERE mi.AffID = a.AffId)
					AND
					(
						(@IsGetAll = 1 AND mi.IsRemoved = 0)
						OR NOT EXISTS (
							SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
							WHERE
								mr.IBCCustID = mi.IBCCustID
								AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
						)
					)
					AND mi.IBCCustID = md.IBCCustID
			)
		GROUP BY md.AffID

		UNION ALL
		SELECT md.AffID, COUNT(DISTINCT md.IBCCustID) AS Active
		FROM dbo.MemberDaily md WITH(NOLOCK)
		WHERE (@IsGetAll = 1 OR md.WinlostDate BETWEEN @FromDate AND @ToDate)
			AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = md.AffID)
			AND EXISTS (
				SELECT 1
				FROM [DBDeposit].deposit_db.dbo.Deposit_Customer dc WITH (NOLOCK)
				WHERE (@IsGetAll = 1 OR dc.CreatDate BETWEEN @FromDate AND @ToDate)
					AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = dc.AffiliateId)
					AND dc.IBCCustID = md.IBCCustID
			)
		GROUP BY md.AffID
	)
	UPDATE d
	SET d.Active = ISNULL(dep.Active, 0), d.Dormant = d.FDMs - ISNULL(dep.Active, 0)
	FROM #AffTotal d
		LEFT JOIN (
				SELECT AffID, MAX(Active) AS Active FROM ActiveMember GROUP BY AffID
			) dep ON d.AffId = dep.AffID
	
	-- sum total
	SELECT
		AffId,
		Username,
		ISNULL(Active, 0) AS Active,
		ISNULL(Dormant, 0) AS Dormant,
		ISNULL(FDMs, 0) AS Total,
		ISNULL(Signups, 0) AS TotalRegistered,
		RowIDX
	FROM #AffTotal
	ORDER BY RowIDX

	DROP TABLE #AffTotal
END
GO