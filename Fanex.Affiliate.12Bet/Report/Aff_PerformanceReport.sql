ALTER PROCEDURE [dbo].[Aff_PerformanceReport] 
	@UserName VARCHAR(50) = NULL
	,@Language VARCHAR(11) = NULL
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@SortBy VARCHAR(20) = 'Member'
	,@SportId INT = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*  
	Created: @VinhTrinh  
	Task : Show performance report for admin.  
	DB: DB052.Affiliate_12BET  
	Original: [Aff_AffiliateReport]  
	Revisions:  
	   - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])  
	   - 20120606@Peter : Exclude waiting tickets  
  
	Param's Explanation:  
	 • @UserName Search by username  
	 • @Language Search by language  
	 • @FromDate From date  
	 • @ToDate To date  
	 • @SortBy Sort by field  
	 If @SortBy=Commission and  
	 @SportID=0 : View all  
			  1: View by Sportsbook  
		3: View by Casino  
*/
BEGIN
	SET NOCOUNT ON

	IF @FromDate > @ToDate RETURN

	CREATE TABLE #Result (
		AffId INT PRIMARY KEY
		,Username VARCHAR(50)
		,QualifiedMembers INT
		,ActivePlayer INT
		,Deposit MONEY
		,Withdrawal MONEY
		,Turnover MONEY
		,Winlost MONEY
		,Commission MONEY
		)

	DECLARE @CurrentDate SMALLDATETIME
		,@LastMonthlydate SMALLDATETIME
		,@FirstDate SMALLDATETIME
		,@TmpToDate SMALLDATETIME
		,@NoComGroupID INT

	--Assign @ToDate to last date of @ToDate, @FromDate equal 1st of @fromdate  
	SELECT @CurrentDate = dateadd(d, 0, datediff(d, 0, current_timestamp))
		,@FromDate = dateadd(m, datediff(m, 0, @FromDate), 0) --Assign fromdate to 1st of month of fromdate  
		,@ToDate = dateadd(d, - 1, dateadd(m, datediff(m, 0, @ToDate) + 1, 0)) --Assign todate to last date of month of todate  
		,@TmpToDate = @ToDate

	IF (@ToDate >= @CurrentDate)
	BEGIN
		SELECT @TmpToDate = DateAdd(d, - 1, @CurrentDate) --To Exclude current date for calculating affdaily table  
	END

	SELECT @LastMonthlydate = max(WinlostDate)
	FROM AffCommission(NOLOCK)

	SELECT @FirstDate = dateadd(d, 1, @LastMonthlydate)

	SELECT @UserName = '%' + isnull(@UserName, '') + '%'

	SELECT @Language = '%' + isnull(@Language, '') + '%'

	SELECT @NoComGroupID = GroupID
	FROM CommGroup(NOLOCK)
	WHERE GroupName = 'NoCommission'

	--Get list aff sastify search condition  
	INSERT INTO #Result (
		AffId
		,Username
		,QualifiedMembers
		,ActivePlayer
		,Deposit
		,Withdrawal
		,Turnover
		,Winlost
		,Commission
		)
	SELECT ad.AffId
		,ad.Username
		,0
		,0
		,0
		,0
		,0
		,0
		,0
	FROM AffDetail ad WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK)
		ON ad.AffId = ai.AffId
	WHERE ad.Username LIKE @UserName
		AND PreferredLanguage LIKE @Language
		AND ai.ApprovedDate < @ToDate
		--Exclude all closed affs   
		AND (
			ai.IsClosed = 0
			OR ai.GroupID <> @NoComGroupID
			)
		AND ai.STATUS = 'approved'

	SELECT @NRows = @@ROWCOUNT

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	UPDATE r
	SET r.QualifiedMembers = isnull(t.QualifiedMembers, 0)
		,r.ActivePlayer = isnull(t.ActivePlayer, 0)
		,r.Deposit = isnull(t.Deposit, 0)
		,r.Withdrawal = isnull(t.Withdrawal, 0)
		,r.Turnover = isnull(t.Turnover, 0)
		,r.Winlost = isnull(t.Winlost, 0)
		,r.Commission = isnull(t.Commission, 0)
	FROM #Result r WITH (ROWLOCK, UPDLOCK)
		LEFT JOIN (
		SELECT tmp.AffId
			,tmp.Username
			,Sum(QualifiedMember) AS QualifiedMembers
			,Sum(ActivePlayer) AS ActivePlayer
			,Sum(MemberDeposit) AS Deposit
			,Sum(Withdrawal) AS Withdrawal
			,Sum(MemberTurnover) AS Turnover
			,Sum(MemberWinlost) AS Winlost
			,Sum(Commission) AS Commission
		FROM (
			---@sportID in order to exclude bettrans in case for casino commission   
			SELECT @SportId AS SportId
				,a.AffId
				,a.Username
				,Sum(ac.QualifiedMember) AS QualifiedMember
				,0 AS ActivePlayer
				,Sum(ac.MemberDeposit) AS MemberDeposit
				,0 AS Withdrawal
				,Sum(ac.MemberTurnover) AS MemberTurnover
				,Sum(ac.MemberWinlost) AS MemberWinlost
				,Sum(ac.AffWinlost) AS Commission
			FROM #Result a(NOLOCK)
				INNER JOIN AffCommission ac WITH (NOLOCK)
				ON a.AffId = ac.AffId
			WHERE ac.WinlostDate BETWEEN @FromDate AND @ToDate
				AND SportId = @SportId
			GROUP BY a.AffId
				,a.Username
			
			UNION ALL
			--Calculate Withdrawal  
			SELECT 1 AS SportId
				,a.AffId
				,a.Username
				,0 AS QualifiedMember
				,0 AS ActivePlayer
				,0 AS MemberDeposit
				,Sum(isnull(af.Amount, 0)) AS Withdrawal
				,0 AS MemberTurnover
				,0 AS MemberWinlost
				,0 AS Commission
			FROM #Result a(NOLOCK)
				INNER JOIN AffTrans af WITH (NOLOCK)
				ON a.AffId = af.AffId
			WHERE af.CompletedDate BETWEEN @FromDate AND @ToDate
				AND af.transtype = 202
				AND af.STATUS = 'Approved' --For withdrawal     
			GROUP BY a.AffId
				,a.Username
			
			UNION ALL
			--Calculate Active player  
			SELECT m.SportType AS SportId
				,a.AffId
				,a.Username
				,0 AS QualifiedMember
				,count(DISTINCT IBCCustID) AS ActivePlayer
				,0 AS MemberDeposit
				,0 AS Withdrawal
				,0 AS MemberTurnover
				,0 AS MemberWinlost
				,0 AS Commission
			FROM #Result a(NOLOCK)
				INNER JOIN memberdaily m WITH (NOLOCK)
				ON a.AffId = m.AffId
			WHERE WinlostDate BETWEEN @FromDate AND @ToDate
				AND (
					isnull(m.TurnOver, 0) > 0
					OR isnull(m.Deposit, 0) > 0
					)
				AND m.SportType = @SportId
			GROUP BY m.SportType
				,a.AffId
				,a.Username
			) AS tmp
		WHERE SportId = @SportId
		GROUP BY tmp.AffId
			,tmp.Username
		) t
		ON r.AffID = t.AffID;

	DECLARE @temp TABLE (
		AffId INT PRIMARY KEY
		,Username VARCHAR(50)
		,QualifiedMembers INT
		,ActivePlayer INT
		,Deposit MONEY
		,Withdrawal MONEY
		,Turnover MONEY
		,Winlost MONEY
		,Commission MONEY
		)

	INSERT INTO @temp (
		AffId
		,Username
		,QualifiedMembers
		,ActivePlayer
		,Deposit
		,Withdrawal
		,Turnover
		,Winlost
		,Commission
		)
	SELECT AffId
		,Username
		,QualifiedMembers
		,ActivePlayer
		,Deposit
		,Withdrawal
		,Turnover
		,Winlost
		,Commission
	FROM (
		SELECT ROW_NUMBER() OVER (
				ORDER BY (CASE 
						WHEN @SortBy = 'Member' THEN QualifiedMembers
						WHEN @SortBy = 'Deposit' THEN Deposit
						WHEN @SortBy = 'Turnover' THEN Turnover
						WHEN @SortBy = 'Winlost' THEN Winlost
						WHEN @SortBy = 'Commission' THEN Commission
						ELSE AffId END
						) DESC
				) AS TheCount
			,AffId
			,Username
			,QualifiedMembers
			,ActivePlayer
			,Deposit
			,Withdrawal
			,Turnover
			,Winlost
			,Commission
		FROM #Result(NOLOCK)
		) m
	WHERE m.TheCount BETWEEN @RowStart AND @RowEnd

	DROP TABLE #Result

	IF (DATEDIFF(M, @CurrentDate, @ToDate) >= 0)
	BEGIN
		UPDATE t
		SET t.QualifiedMembers = t.QualifiedMembers + coalesce(a.TotalQM, 0)
			,t.Deposit = t.Deposit + coalesce(a.MemDeposit, 0)
			,t.Turnover = t.Turnover + coalesce(a.MemTurnover, 0)
			,t.Winlost = t.Winlost + coalesce(a.MemWinlost, 0)
			,t.Commission = t.Commission + coalesce(a.Amount, 0)
		FROM @temp AS t
			CROSS APPLY [dbo].[Aff_CommissionForCurrentMonth](t.AffID) AS a
		WHERE a.SportID = @SportId
	END

	DECLARE @Month INT
		,@Year INT

	SELECT @Month = month(dateadd(m, - 1, @CurrentDate))
		,@Year = Year(dateadd(m, - 1, @CurrentDate))

	IF (
			datediff(m, @LastMonthlydate, @CurrentDate) > 1
			AND @FromDate = @FirstDate
			)
	BEGIN --For previous month that is not transfered  
		UPDATE t
		SET t.QualifiedMembers = t.QualifiedMembers + coalesce(a.TotalQM, 0)
			,t.Deposit = t.Deposit + coalesce(a.MemDeposit, 0)
			,t.Turnover = t.Turnover + coalesce(a.MemTurnover, 0)
			,t.Winlost = t.Winlost + coalesce(a.MemWinlost, 0)
			,t.Commission = t.Commission + coalesce(a.Amount, 0)
		FROM @temp AS t
			CROSS APPLY [dbo].[Aff_CommissionForMonth](t.AffID, @Month, @Year) AS a
		WHERE a.SportID = @SportId
	END

	SELECT *
	FROM (
		SELECT ROW_NUMBER() OVER (
				ORDER BY (CASE 
						WHEN @SortBy = 'Member' THEN QualifiedMembers
						WHEN @SortBy = 'Deposit' THEN Deposit
						WHEN @SortBy = 'Turnover' THEN Turnover
						WHEN @SortBy = 'Winlost' THEN Winlost
						WHEN @SortBy = 'Commission' THEN Commission
						ELSE AffId END
						) DESC
				) AS TheCount
			,AffId
			,Username
			,QualifiedMembers
			,ActivePlayer
			,Deposit
			,Withdrawal
			,Turnover
			,Winlost
			,Commission
		FROM @Temp
		) t
	ORDER BY TheCount
		,AffID
END
GO

GRANT EXECUTE ON [dbo].[Aff_PerformanceReport] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_PerformanceReport] TO [VNTeam]
GO


