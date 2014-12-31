ALTER PROCEDURE [dbo].[Aff_PerformanceReport] 
	@UserName			VARCHAR(50) = NULL
	,@Language			VARCHAR(11) = NULL
	,@FromDate			DATETIME
	,@ToDate			DATETIME
	,@SortBy			TINYINT		= 1
	,@IsDesc			BIT			= 1
	,@SportId			INT			= NULL
	,@PageSize			INT			= 50
	,@PageIndex			INT			= 1
	,@NRows				INT			= 0 OUTPUT
AS
/*
Created: @VinhTrinh
Task : Show performance report for admin.
DB: DB052.Affiliate_12BET
Original: [Aff_AffiliateReport]
Revisions:
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120606@Peter : Exclude waiting tickets
	- 20141118@Bobby: 
		+ Add sorting [@IsDesc] value
		+ Remove @TotalPages
	- 20141218@Bobby: Enhance performance & update SS's bettype

Param's Explanation:
	• @UserName Search by username
	• @Language Search by language
	• @FromDate From date
	• @ToDate	To date
	• @SortBy	0 Affilate
		+ 1 - QualifiedMembers
		+ 2 - Deposit
		+ 3 - Turnover
		+ 4 - Winlost
		+ 5 - Commission

	If @SortBy=Commission and
	@SportID=0 : View all
	    1: View by Sportsbook
		3: View by Casino
*/
BEGIN
	SET NOCOUNT ON

	IF @FromDate > @ToDate RETURN
	
	DECLARE @Month	INT
		,@Year		INT
		
	CREATE TABLE #AffList (
		AffId		INT
		, UserName	VARCHAR(30)
		, IsClosed	BIT
		, Currency 	INT
	)

	CREATE TABLE #AffReport (
		AffId	INT
		,ToTal	FLOAT
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
	
	CREATE TABLE #AffComm (
		AffId		INT
		, TotalQM	INT
		, Deposit	MONEY
		, Tunover	MONEY
		, Winlost	MONEY
		, AffComm	MONEY
	)
	
	DECLARE @AffPaging 
	AS TABLE  (
		AffId	INT
		,RowIDX	INT
	)
	
	
	DECLARE @CurrentDate 	SMALLDATETIME
		,@LastMonthlydate 	SMALLDATETIME
		,@FirstDate 		SMALLDATETIME
		,@TmpToDate 		SMALLDATETIME
		,@NoComGroupID 		INT
		,@CurrMonth			DATE

	--Assign @ToDate to last date of @ToDate, @FromDate equal 1st of @fromdate
	SELECT @CurrentDate 	= DATEADD(d, 0, datediff(d, 0, CURRENT_TIMESTAMP))
		,@FromDate 			= DATEADD(m, datediff(m, 0, @FromDate), 0) --Assign fromdate to 1st of month of fromdate
		,@ToDate 			= DATEADD(d, - 1, DATEADD(m, datediff(m, 0, @ToDate) + 1, 0)) --Assign todate to last date of month of todate
		,@TmpToDate 		= @ToDate
		,@CurrMonth 		= DATEADD(M, DATEDIFF(M, 0, @CurrentDate), 0)
		,@Month				= MONTH(@CurrentDate)
		,@Year				= YEAR(@CurrentDate)

	IF (@ToDate >= @CurrentDate)
	BEGIN
		SELECT @TmpToDate = DATEADD(d, - 1, @CurrentDate) --To Exclude current date for calculating affdaily table
	END

	SELECT @LastMonthlydate = MAX(WinlostDate)
	FROM dbo.AffCommission WITH (NOLOCK)

	SELECT @FirstDate 	= DATEADD(d, 1, @LastMonthlydate)
		,@UserName 		= '%' + isnull(@UserName, '') + '%'
		,@Language 		= '%' + isnull(@Language, '') + '%'

	SELECT 
		@NoComGroupID 	= GroupID
	FROM dbo.CommGroup WITH (NOLOCK)
	WHERE GroupName = 'NoCommission'
	

	--Get list aff sastify search condition
	INSERT INTO #AffList( AffId, UserName, IsClosed, Currency )
	SELECT ai.AffId
		,ai.UserName
		,ai.IsClosed
		,ai.Currency
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) 
		ON ai.AffId = ad.AffId
		
	WHERE ad.Username LIKE @UserName
		AND ad.PreferredLanguage LIKE @Language
		AND ai.ApprovedDate < @ToDate
		AND ai.STATUS = 'Approved'
	
	IF (@@ROWCOUNT = 0) RETURN

	--For old month that was calculated
	INSERT INTO #AffReport (AffId, ToTal)
	SELECT ac.AffId
		,CASE WHEN @SortBy = 1 THEN SUM(ac.QualifiedMember)
			WHEN @SortBy = 2 THEN SUM(ac.MemberDeposit)
			WHEN @SortBy = 3 THEN SUM(ac.MemberTurnover)
			WHEN @SortBy = 4 THEN SUM(ac.MemberWinlost)
			WHEN @SortBy = 5 THEN SUM(ac.AffWinlost)
			ELSE 0
		END AS Total
	FROM dbo.AffCommission ac WITH (NOLOCK)
		INNER JOIN #AffList a WITH (NOLOCK) 
		ON ac.AffId = a.AffId

	WHERE ac.WinlostDate BETWEEN @FromDate AND (CASE WHEN @ToDate > @LastMonthlydate THEN @LastMonthlydate ELSE @ToDate END)
		AND (@SportId IS NULL OR ac.SportId = @SportId)

	GROUP BY ac.AffId
	
	HAVING SUM(ac.QualifiedMember) > 0
		OR SUM(ac.MemberDeposit) > 0
		OR SUM(ac.MemberTurnover) > 0
		OR ABS(SUM(ac.MemberWinlost)) > 0
		OR ABS(SUM(ac.AffWinlost)) > 0
	
	--For current month that is not calculated
	IF (DATEDIFF(M, @CurrentDate, @ToDate) = 0)
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
			
		
		INSERT INTO #AffReport (AffId, ToTal)
		SELECT ac.AffId
			,CASE WHEN @SortBy = 1 THEN SUM(ac.TotalQM)
				WHEN @SortBy = 2 THEN SUM(ac.Deposit)
				WHEN @SortBy = 3 THEN SUM(ac.Turnover)
				WHEN @SortBy = 4 THEN SUM(ac.Winlost)
				WHEN @SortBy = 5 THEN SUM(ac.Commission)
				ELSE 0
			END AS Total
		FROM #AffCommTmp ac
		GROUP BY ac.AffId
	END
	

	--For previous month that was not calculated
	IF( DATEDIFF(MM, @LastMonthlyDate, @ToDate) > 1
		AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.AffCommission WITH (NOLOCK) WHERE WinlostDate = DATEADD(MM,1, @LastMonthlyDate)))
	BEGIN 
		SELECT @Month	= MONTH(DATEADD(m, - 1, @CurrentDate))
			,@Year		= YEAR(DATEADD(m, - 1, @CurrentDate))
		
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
			
		INSERT INTO #AffReport (AffId, ToTal)
		SELECT ac.AffId
			,CASE WHEN @SortBy = 1 THEN SUM(ac.TotalQM)
				WHEN @SortBy = 2 THEN SUM(ac.Deposit)
				WHEN @SortBy = 3 THEN SUM(ac.Turnover)
				WHEN @SortBy = 4 THEN SUM(ac.Winlost)
				WHEN @SortBy = 5 THEN SUM(ac.Commission)
				ELSE 0
			END AS Total
		FROM #AffCommTmp ac
		GROUP BY ac.AffId
	END

	-- SET @NRows
	SELECT @NRows = COUNT(1)
	FROM (
		SELECT a.AffId
		FROM #AffList a
		INNER JOIN #AffReport rpt
			ON a.AffId = rpt.AffId
			
		WHERE 1 = (CASE WHEN @SortBy <> 0 AND rpt.Total <> 0 THEN 1 ELSE 1 END)
		
		GROUP BY a.AffId
	) r
	
	-- get aff paging list
	INSERT INTO @AffPaging(AffId, RowIDX)
	SELECT AffId, RowIDX
	FROM (
		SELECT a.AffId
		,ROW_NUMBER() OVER ( 
				ORDER BY 
					CASE WHEN @SortBy = 0 AND @IsDesc = 1 THEN a.AffId
						ELSE 0
					END DESC
					,CASE WHEN @SortBy = 0 AND @IsDesc = 0 THEN a.AffId
						ELSE 0
					END ASC
					,CASE WHEN @IsDesc = 1 THEN SUM(ISNULL(rpt.Total, 0))
						ELSE 0
					END DESC
					,CASE WHEN @IsDesc = 0 THEN SUM(ISNULL(rpt.Total, 0))
						ELSE 0
					END ASC
					
					
			) AS RowIDX
		FROM #AffList a
			INNER JOIN #AffReport rpt
			ON a.AffId = rpt.AffId
			
		WHERE 1 = (CASE WHEN @SortBy <> 0 AND rpt.Total <> 0 THEN 1 ELSE 1 END)
		
		GROUP BY a.AffId
	) t
	WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY t.RowIDX
	
	-- get data from calculated month that was calculated
	INSERT INTO #AffComm(AffId, TotalQM, Deposit, Tunover, Winlost, AffComm)
	SELECT AffId
		, SUM(TotalQM)
		, SUM(Deposit)
		, SUM(Tunover)
		, SUM(Winlost)
		, SUM(AffComm)
	FROM (
		SELECT ac.AffId
			,SUM(ac.QualifiedMember) AS TotalQM
			,SUM(ac.MemberDeposit) as Deposit
			,SUM(ac.MemberTurnover) as Tunover
			,SUM(ac.MemberWinlost) as Winlost
			,SUM(ac.AffWinlost) as AffComm
		FROM dbo.AffCommission ac (NOLOCK)
			INNER JOIN @AffPaging p
			ON ac.AffID = p.AffId

		WHERE ac.WinlostDate BETWEEN @FromDate AND (CASE WHEN @ToDate > @LastMonthlydate THEN @LastMonthlydate ELSE @ToDate END)
			AND (@SportId IS NULL OR ac.SportId = @SportId)

		GROUP BY ac.AffID
		
		HAVING SUM(ac.QualifiedMember) > 0
			OR SUM(ac.MemberDeposit) > 0
			OR SUM(ac.MemberTurnover) > 0
			OR ABS(SUM(ac.MemberWinlost)) > 0
			OR ABS(SUM(ac.AffWinlost)) > 0
		
		-- get data from un-calculated month that was not calculated
		UNION ALL
		SELECT a.AffId
			, SUM(ac.TotalQM) AS TotalQM
			, SUM(ac.Deposit) AS Deposit
			, SUM(ac.Turnover) AS Turnover
			, SUM(ac.Winlost) AS Winlost
			, SUM(ac.Commission) AS AffComm
		FROM @AffPaging a
			INNER JOIN #AffCommTmp ac 
			ON a.AffId = ac.AffId
		WHERE (@SportId IS NULL OR ac.SportId = @SportId)
		GROUP BY a.AffId
	) t
	GROUP BY t.AffId
	
	-- get affiliate withdrawal
	;WITH AffWithdraw (AffId, Withdrawal)
	AS (
		SELECT af.AffId
			,SUM(isnull(af.Amount, 0)) AS Withdrawal
		FROM dbo.AffTrans af WITH(NOLOCK)
			INNER JOIN @AffPaging r
			ON af.AffId = r.AffId
		WHERE af.CompletedDate BETWEEN @FromDate
				AND @ToDate
			AND af.transtype = 202
			AND af.STATUS = 'Approved' --For withdrawal 		
		GROUP BY af.AffId
	)
	-- get affiliate active member
	, ActiveMember (AffId, ActivePlayer)
	AS (
		SELECT md.AffId
			,COUNT(DISTINCT IBCCustID) AS ActivePlayer
				
		FROM dbo.MemberDaily md WITH(NOLOCK)
			INNER JOIN @AffPaging rpt
			ON md.AffId = rpt.AffId

		WHERE md.WinlostDate BETWEEN @FromDate
				AND @ToDate
			AND (
				ISNULL(md.TurnOver, 0) > 0
				OR ISNULL(md.Deposit, 0) > 0
				)
			AND md.SportType = @SportId

		GROUP BY md.AffId
	)
	-- fetch final result
	SELECT p.AffId
		,ai.UserName
		
		,SUM(ISNULL(c.TotalQM, 0))			AS QualifiedMembers
		,SUM(ISNULL(c.Deposit, 0))			AS Deposit
		,SUM(ISNULL(c.Tunover, 0))			AS Turnover
		,SUM(ISNULL(c.Winlost, 0))			AS Winlost
		,SUM(ISNULL(c.AffComm, 0))			AS Commission
		,SUM(ISNULL(aw.Withdrawal, 0))		AS Withdrawal
		,SUM(ISNULL(am.ActivePlayer, 0))	AS ActivePlayer
		
		,p.RowIDX
	FROM @AffPaging p
		
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON p.AffId = ai.AffID

		LEFT JOIN #AffComm c
		ON p.AffId = c.AffId

		LEFT JOIN AffWithdraw aw
		ON p.AffId = aw.AffId

		LEFT JOIN ActiveMember am
		ON p.AffId = am.AffId

	GROUP BY p.AffId
		,ai.UserName
		,p.RowIDX

	ORDER  BY p.RowIDX

	DROP TABLE #AffList
	DROP TABLE #AffReport
	DROP TABLE #AffComm
	DROP TABLE #AffCommTmp
	
	RETURN

END
GO 

GRANT EXECUTE ON [dbo].[Aff_PerformanceReport] TO [bodbAdminNet]
GO 


/*
declare @NRows int
exec [dbo].[Aff_PerformanceReport_xtest] 
	@FromDate			= '2014/11/01'
	,@ToDate			= '2014/12/01'
	,@sortby = 0
	,@PageSize			= 20
	,@PageIndex			= 25
	,@NRows = @NRows output
select @NRows
*/
	
	