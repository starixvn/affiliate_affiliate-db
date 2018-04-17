/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateCommReport] 
	@MonthDate 				DATETIME 		= NULL
	,@SportId 				TINYINT 		= NULL
	,@UserName 				NVARCHAR(50)	= NULL
	,@PreferredLanguage 	VARCHAR(11) 	= NULL
	,@AffType 				TINYINT			= NULL
	,@PageSize 				INT 			= 50
	,@PageIndex 			INT 			= 1
	,@SortBy				TINYINT 		= 0
	,@IsDesc				BIT				= 1
	,@NRows 				INT 			= 0 OUTPUT
AS

/*
	Created: @Peter
	Task: Get report of Active members 
	DB: DBAFF12BET.Affiliate_12BET
	Original: [Aff_AffiliateCommReport]

	Revisions:
		-20120508@Johnny: Add dropdown box for sport type
		- 20141118@Bobby: 
			+ Add sorting [@SortBy] value
			+ Remove @TotalPages
		- 20141218@Bobby: Enhance performance & update SS's bettype
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		
	Param's Explanation:
		• @Fromdate Time search From
		• @Todate Time search To,
		• @IsGetAll if getall = 1 => get data in all date,
		• @UserName Affiliate username need to search(must match username),
		• @PageSize Page Size,
		• @PageIndex Current page,
		• @TotalPages num pages return,
		• @NRows num rows return
		• @SortBy: Default(0) - AffId ASC, 1 -  Earning desc
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Todate 	DATETIME
		,@month 		INT
		,@year 			INT
		,@SportbookId 	INT
		,@CasinoId 		INT
		
	CREATE TABLE #AffList (
		AffId		INT
		, UserName	VARCHAR(30)
		, IsClosed	BIT
		, Currency 	INT
		, DeductedPercentage DECIMAL(9,8)
	)
	CREATE TABLE #AffCommTmp (
		AffId INT
		,GroupID INT
		,SportID TINYINT
		,MonthDate SMALLDATETIME
		,TotalQM INT
		,CommRate FLOAT
		,Commission MONEY
		,Deposit MONEY
		,TurnOver MONEY
		,Winlost MONEY
		,NetWinlost MONEY
	)
	CREATE TABLE #AffCommPaging (
		AffId		INT
		, SportID	INT
		, CommRate	FLOAT
		, Amount	MONEY
		, RowIDX	INT
	)
	
	SELECT @UserName = '%' + COALESCE(@UserName, '') + '%'

	SELECT @MonthDate 	= convert(VARCHAR(10), DATEADD(s, - 1, DATEADD(mm, DATEDIFF(m, 0, @MonthDate) + 1, 0)), 120)
		,@ToDate 		= dateadd(d, - 1, dateadd(m, datediff(m, 0, @MonthDate) + 1, 0)) --Assign todate to last date of month of todate
		,@month 		= MONTH(@MonthDate)
		,@year 			= YEAR(@MonthDate)

	SELECT @SportbookId = dbo.Aff_GetSportID('SportsBook')
		,@CasinoId 		= dbo.Aff_GetSportID('Casino')

	--count nrows
	INSERT INTO #AffList( AffId, UserName, IsClosed, Currency, DeductedPercentage )
	SELECT ai.AffId
		,ai.UserName
		,ai.IsClosed
		,ai.Currency
		,ISNULL(ds.DeductedPercentage, 0)
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK)  ON ai.AffId = ad.AffId
		LEFT JOIN dbo.DeductionSetting ds WITH(NOLOCK) ON ai.GroupID = ds.GroupID AND ds.DeductionID = 9
	WHERE ai.STATUS = 'Approved'
		AND ai.Username LIKE @UserName
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage)
		AND (@AffType IS NULL OR ai.AffType = @AffType)
		AND ai.ApprovedDate < @ToDate
	
	IF (@@ROWCOUNT = 0) RETURN

	IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.AffCommission(NOLOCK) WHERE winlostdate = @MonthDate)
	BEGIN
		IF (DATEDIFF(m, CURRENT_TIMESTAMP, @MonthDate) = 0)
		BEGIN
			INSERT INTO #AffCommTmp(
				AffId
				,GroupID
				,SportID
				,MonthDate
				,TotalQM
				,CommRate
				,Commission
				,Deposit
				,TurnOver
				,Winlost
				,NetWinlost
			)
			EXEC [dbo].[Aff_AffiliateCommByMonthAll]  @Month, @Year, @SportId

			--calculate for current month and display the data
			INSERT INTO #AffCommPaging(AffId, SportId, CommRate, Amount, RowIDX)
			SELECT AffId, SportId, CommRate, Amount, RowIDX
			FROM (
				SELECT l.AffId
					,a.SportId
					,COALESCE(a.CommRate, 0) AS CommRate
					,COALESCE(a.commission, 0) AS Amount
					,ROW_NUMBER() OVER ( 
						ORDER BY l.IsClosed ASC 
								,CASE WHEN @SortBy = 1 AND @IsDesc = 1 THEN COALESCE(a.commission, 0) END DESC
								,CASE WHEN @SortBy = 1 AND @IsDesc = 0 THEN COALESCE(a.commission, 0) END ASC
								,CASE WHEN @SortBy = 0 AND @IsDesc = 1 THEN a.AffId END DESC
								,CASE WHEN @SortBy = 0 AND @IsDesc = 0 THEN a.AffId END ASC
					) AS RowIDX
				FROM #AffList l
					INNER JOIN #AffCommTmp a ON l.AffId = a.AffId
				WHERE (@SportId IS NULL OR a.SportId = @SportId)
			) t
			WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
			ORDER BY t.RowIDX 	
		END
		ELSE
		BEGIN
			--calculate for specific month and display the data
			INSERT INTO #AffCommTmp(
				AffId
				,GroupID
				,SportID
				,MonthDate
				,TotalQM
				,CommRate
				,Commission
				,Deposit
				,TurnOver
				,Winlost
				,NetWinlost
			)
			EXEC [dbo].[Aff_AffiliateCommByMonthAll]  @Month, @Year, @SportId
			
			INSERT INTO #AffCommPaging(AffId, SportId, CommRate, Amount, RowIDX)
			SELECT AffId, SportId, CommRate, Amount, RowIDX
			FROM (
				SELECT l.AffId
					,a.SportId
					,COALESCE(a.CommRate, 0) AS CommRate
					,COALESCE(a.commission, 0) AS Amount
					,ROW_NUMBER() OVER ( 
						ORDER BY l.IsClosed ASC 
								,CASE WHEN @SortBy = 1 AND @IsDesc = 1 THEN COALESCE(a.commission, 0) ELSE 0 END DESC
								,CASE WHEN @SortBy = 1 AND @IsDesc = 0 THEN COALESCE(a.commission, 0) ELSE 0 END ASC
								,CASE WHEN @SortBy = 0 THEN a.AffId ELSE 0 END ASC
					) AS RowIDX
				FROM #AffList l
					INNER JOIN #AffCommTmp a ON l.AffId = a.AffId
				WHERE (@SportId IS NULL OR a.SportId = @SportId)
			) t
			WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
			ORDER BY t.RowIDX 
		END

		SELECT @NRows = COUNT(1)
		FROM ( SELECT l.AffId
					, a.SportId
					, l.IsClosed 
			FROM #AffList l
				INNER JOIN #AffCommTmp a ON l.AffId = a.AffId
			WHERE (@SportId IS NULL OR a.SportId = @SportId)
			GROUP BY l.AffId
					, a.SportId
					, l.IsClosed 
		) t

	END
	ELSE
	BEGIN
		INSERT INTO #AffCommPaging(AffId, SportId, CommRate, Amount, RowIDX)
		SELECT AffId, SportId, CommRate, Amount, RowIDX
		FROM (
			SELECT m.AffId
				,ac.SportId 
				,SUM(ISNULL(ac.Commission, 0)) AS CommRate
				,SUM(ISNULL(ac.AffWinlost, 0)) AS Amount
				,ROW_NUMBER() OVER ( 
					ORDER BY m.IsClosed ASC
							,CASE WHEN @SortBy = 1 AND @IsDesc = 1 THEN SUM(ISNULL(ac.AffWinlost, 0)) ELSE 0 END DESC
							,CASE WHEN @SortBy = 1 AND @IsDesc = 0 THEN SUM(ISNULL(ac.AffWinlost, 0)) ELSE 0 END ASC
							,CASE WHEN @SortBy = 0 THEN m.AffId ELSE 0 END ASC
				) AS RowIDX
			FROM dbo.AffCommission ac WITH (NOLOCK)
				INNER JOIN #AffList m ON ac.AffId = m.AffId
			WHERE ac.WinlostDate = @MonthDate
				AND (@SportId IS NULL OR ac.SportId = @SportId)
			GROUP BY m.AffId
				,ac.SportId 
				, m.IsClosed 
		) t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
		ORDER BY t.RowIDX

		SELECT @NRows = COUNT(1)
		FROM ( SELECT m.AffId
				, ac.SportId
				, m.IsClosed 
			FROM dbo.AffCommission ac WITH (NOLOCK)
				INNER JOIN #AffList m ON ac.AffId = m.AffId
			WHERE ac.WinlostDate = @MonthDate
				AND (@SportId IS NULL OR ac.SportId = @SportId)
			GROUP BY m.AffId
					, ac.SportId
					, m.IsClosed 
		) t
	END
	
	--Select the result Data in order
	SELECT t.AffId
		,t.SportId
		,m.Username
		,m.IsClosed
		,t.CommRate AS Commission
		,t.Amount 	AS AffComm
		,t.RowIDX
	FROM #AffCommPaging t
		INNER JOIN #AffList m ON t.AffId = m.AffId
	ORDER BY t.RowIDX
	
	DROP TABLE #AffCommPaging
	DROP TABLE #AffCommTmp
	DROP TABLE #AffList
END
GO