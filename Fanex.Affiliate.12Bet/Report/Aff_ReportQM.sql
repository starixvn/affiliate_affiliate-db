USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_ReportQM] 
	@AffName 			VARCHAR(50) = NULL
	,@PreferredLanguage VARCHAR(11) = NULL
	,@Month 			INT
	,@Year 				INT
	,@PageSize 			INT 		= 50
	,@PageIndex 		INT 		= 1
	,@SortBy			TINYINT		= 0
	,@NRows 			INT 		= 0 OUTPUT
AS

/*
	Created: 20091213@Peter
	Task: Get Qualifying member report for all affiliates.
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20110523@Henry: change bettype to new range
		- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20120508@Johnny: Add Casino 
		- 20120606@Peter : Exclude waiting tickets
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20141114@Bobby: 
			+ Add sorting [@SortBy] value
			+ Remove @TotalPages
		- 20141218@Bobby: Enhance performance & update SS's bettype
		- 20141223@Bobby: Hotfix#28059 - Filtering by PreferredLanguage
		- 20150923@Bobby: Update formular of QM calculation change ">" to  ">="

	Param's Explanation:
		• @SortBy:
			0: AffId ASC
			1 - Sportsbook QM DESC
			3 - Casino QM DESC
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffList TABLE
	(
		AffId		INT
		,UserName	VARCHAR(30)
	)
	
	DECLARE @FirstDay 	SMALLDATETIME
		,@LastDay 		SMALLDATETIME
		,@SportsBookID 	INT
		,@HorseRacingID INT
		,@CasinoID 		INT
		,@MaxWinlostDate SMALLDATETIME
		,@NoComGroupID 	INT

	SELECT @SportsBookID 	= dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID 	= dbo.Aff_GetSportID('Horse Racing')
		,@CasinoID 			= dbo.Aff_GetSportID('Casino')

	SELECT @FirstDay = CAST(CAST(@Year AS VARCHAR(5)) + '-' + CAST(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month
	SELECT @LastDay = DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))

	SELECT @MaxWinlostDate = MAX(WinlostDate)
	FROM AffCommission WITH (NOLOCK)

	SELECT @NoComGroupID = GroupID
	FROM CommGroup WITH (NOLOCK)
	WHERE GroupName = 'NoCommission'

	SELECT @AffName = '%' + COALESCE(@AffName, '') + '%'
	
	--search for aff account whom had any transaction in the specific month
	INSERT INTO @AffList( AffId, UserName )
	SELECT ai.AffID, ai.UserName
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.STATUS		= 'Approved'
		AND ai.Username LIKE @AffName
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage)
		AND ai.ApprovedDate < @LastDay
	GROUP BY ai.AffID, ai.UserName
		
	IF (@@ROWCOUNT = 0)
		RETURN
	
	IF (@LastDay <= @MaxWinlostDate) --Get Data from AffCommission
	BEGIN
		SELECT AffId
			,UserName
			,SPQM
			,HRQM
			,CSQM
			,TotalQM
			,RowIDX
		FROM (
			SELECT m.AffId
				,m.UserName
				,SUM(CASE WHEN ac.SportID = @SportsBookID 	THEN ISNULL(ac.QualifiedMember, 0) ELSE 0 END) AS SPQM
				,SUM(CASE WHEN ac.SportID = @HorseRacingID 	THEN ISNULL(ac.QualifiedMember, 0) ELSE 0 END) AS HRQM
				,SUM(CASE WHEN ac.SportID = @CasinoID 		THEN ISNULL(ac.QualifiedMember, 0) ELSE 0 END) AS CSQM
				,SUM(ISNULL(QualifiedMember, 0)) AS TotalQM
				,ROW_NUMBER() OVER ( 
						ORDER BY CASE WHEN @SortBy = 1 THEN SUM(CASE WHEN ac.SportID = @SportsBookID 	THEN ISNULL(QualifiedMember, 0) ELSE 0 END) ELSE 0 END DESC
								,CASE WHEN @SortBy = 3 THEN SUM(CASE WHEN ac.SportID = @CasinoID 		THEN ISNULL(QualifiedMember, 0) ELSE 0 END) ELSE 0 END DESC
								,CASE WHEN @SortBy = 0 THEN m.AffId ELSE 0 END ASC
					) AS RowIDX
			FROM @AffList m
				INNER JOIN dbo.AffCommission ac WITH (NOLOCK) ON m.AffId = ac.AffId
			WHERE ac.WinlostDate = @LastDay
			GROUP BY m.AffId, m.UserName
			HAVING SUM(ISNULL(ac.QualifiedMember, 0)) > 0
		) t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
		ORDER BY t.RowIDX
		
		SELECT @NRows = COUNT(1) 
		FROM (
			SELECT m.AffId
			FROM @AffList m
				INNER JOIN dbo.AffCommission ac WITH (NOLOCK) ON m.AffId = ac.AffId
			WHERE ac.WinlostDate = @LastDay
				AND ISNULL(ac.QualifiedMember, 0) > 0
			GROUP BY m.AffId
			HAVING SUM(ISNULL(ac.QualifiedMember, 0)) > 0
		) t
		
	END
	ELSE --Calculate data for uncalculated month
	BEGIN
		DECLARE @MemList TABLE
		(
			IBCCustId 			INT
			,AffId 				INT
			,ActualRate2 		FLOAT
		)
		CREATE TABLE #AffTotal 
		(
			AffId			INT
			, SPTotal		INT
			, CSTotal		INT
			, RowIDX		INT
			, NRows			INT
		)
	
		DECLARE @QmTurnOverSP 	MONEY
			,@QmTurnOverHR 		MONEY
			,@QmTurnOverCS 		MONEY
			,@QmDepositCS 		MONEY
			,@CurrDate 			SMALLDATETIME

		SELECT @CurrDate 		= CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
				,@LastDay 		= CASE WHEN @LastDay >= @CurrDate THEN DATEADD(d, - 1, @CurrDate) ELSE @LastDay END

		SELECT @QmTurnOverSP 	= CASE WHEN s.SportID = @SportsBookID 	THEN s.QMTurnOver 	ELSE @QmTurnOverSP 	END
			, @QmTurnOverHR 	= CASE WHEN s.SportID = @HorseRacingID 	THEN s.QMTurnOver 	ELSE @QmTurnOverHR 	END
			, @QmTurnOverCS 	= CASE WHEN s.SportID = @CasinoID 		THEN s.QMTurnOver 	ELSE @QmTurnOverCS 	END
			, @QmDepositCS 		= CASE WHEN s.SportID = @CasinoID 		THEN s.QMDeposit 	ELSE @QmDepositCS 	END
		FROM dbo.SportType s WITH(NOLOCK)

		INSERT INTO @MemList
		SELECT mi.IbcCustId
			,mi.AffId
			,e.ActualRate2
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN @AffList a ON mi.AffId = a.AffId
			INNER JOIN dbo.Exchange_Current e WITH (NOLOCK) ON mi.Currency = e.ExchangeId
		WHERE mi.IsRemoved = 0
		
		--Calculate Turnover for SP & HR & CA
		;WITH SportsbookQM(AffId, Total)
		AS (
			SELECT t.AffId
				,COUNT(1) AS Total
			FROM (
				SELECT AffID
					,IBCCustID
				FROM (
						SELECT m.AffID
							,md.IBCCustID
							,SUM(ISNULL(md.TurnOver, 0) * ISNULL(md.AffExRate, 1)) AS TurnOver
						FROM @AffList m
							LEFT JOIN dbo.MemberDaily md WITH(NOLOCK) ON m.AffId = md.AffId
						WHERE md.WinlostDate BETWEEN @FirstDay AND @LastDay
							AND SportType = @SportsBookID
						GROUP BY m.AffID
							,md.IBCCustID
						
						--Get data from bettrans for SP
						UNION ALL
						SELECT m.AffId 
							, m.IbcCustId
							,SUM(ISNULL(abs(b.stake), 0) * ISNULL(m.ActualRate2, 0)) AS TurnOver
						FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
							INNER JOIN @MemList m ON b.CustId = m.IBCCustId
						WHERE datediff(m, @LastDay, @CurrDate) = 0
							AND b.WinlostDate = @CurrDate
							AND (
								b.bettype <= 999
								OR ( b.bettype BETWEEN 1301 AND 1399) -- SS tickets
								OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
							) --get SB only
							AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
							AND b.bettype NOT IN (1000) --games
							AND b.bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
							AND b.bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
							AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno  
									--and bettype not in (31,32,33,41,42,43)   
							AND b.StatusID NOT IN (101, 102, 103, 121, 1)
						--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
						GROUP BY m.IbcCustId
							,m.AffId
					) a
					GROUP BY IBCCustID
						,AffID
					HAVING SUM(ISNULL(a.TurnOver, 0)) >= @QmTurnOverSP
			) t
			GROUP BY t.AffID
			HAVING COUNT(1) > 0
			
		)
		,CasinoQM (AffId, Total)
		AS (
			SELECT t.AffID 
				,COUNT(1) AS Total
			FROM (
				--Get data from MemberDaily for HR
				SELECT md.AffID 
					,md.IBCCustID
				FROM dbo.MemberDaily md WITH(NOLOCK) 
					INNER JOIN @MemList a ON md.IBCCustId = a.IBCCustId
				WHERE md.WinlostDate BETWEEN @FirstDay AND @LastDay
					AND md.SportType = @CasinoID
				GROUP BY md.AffID
					,md.IBCCustID
				HAVING SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) >= @QmTurnOverCS
					AND SUM(ISNULL(Deposit, 0) * ISNULL(AffExRate, 1)) >= @QmDepositCS
			) t
			GROUP BY t.AffID
			HAVING COUNT(1) > 0
		)
		, TblNRows 
		AS (
			SELECT COUNT(1) AS NRows
			FROM (
				SELECT sp.AffID
				FROM SportsBookQM sp
				
				UNION
				SELECT cs.AffID
				FROM CasinoQM cs
			) AS r
		)
		INSERT INTO #AffTotal(AffId, SPTotal, CSTotal, RowIDX, NRows)
		SELECT t.AffID
			,t.SPTotal
			,t.CSTotal
			,t.RowIDX
			,t.NRows
		FROM (
			SELECT m.AffID
				,ISNULL(sp.Total, 0) AS SPTotal
				,ISNULL(cs.Total, 0) AS CSTotal
				,ROW_NUMBER() OVER ( 
						ORDER BY CASE WHEN @SortBy = 1 THEN ISNULL(sp.Total, 0) ELSE 0 END DESC
								,CASE WHEN @SortBy = 3 THEN ISNULL(cs.Total, 0) ELSE 0 END DESC
								,CASE WHEN @SortBy = 0 THEN m.AffId ELSE 0 END ASC
					) AS RowIDX
				,r.NRows
			FROM @AffList m
				LEFT JOIN SportsBookQM sp ON m.AffID = sp.AffID
				LEFT JOIN CasinoQM cs ON m.AffID = cs.AffID
				CROSS APPLY TblNRows r
			WHERE ISNULL(sp.Total, 0) 	> 0
				OR ISNULL(cs.Total, 0)  > 0
		) t
		WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
		ORDER BY t.RowIDX
		
		SELECT TOP 1 @NRows = NRows FROM #AffTotal
		
		;WITH HorseRacingQM (AffId, Total)
		AS (
			SELECT t.AffID
				,COUNT(1) 	AS Total
			FROM (
				SELECT AffID
					,IBCCustID
				FROM (
						--Get data from MemberDaily for HR
						SELECT IBCCustID
							,md.AffID 
							,SUM(ISNULL(TurnOver, 0) * ISNULL(AffExRate, 1)) AS TurnOver
						FROM dbo.MemberDaily md(NOLOCK)
							INNER JOIN #AffTotal a ON md.AffId = a.AffId
						WHERE md.WinlostDate BETWEEN @FirstDay AND @LastDay
							AND SportType = @HorseRacingID
						GROUP BY IBCCustID
							,md.AffID
						
						--Get data from bettrans for HR
						UNION ALL
						SELECT m.IbcCustId
							,m.AffId 
							,SUM(CASE 
									WHEN bettype IN (33, 43)
										AND liveawayscore = 0 THEN ISNULL(abs(stake), 0) / 2
									ELSE ISNULL(abs(stake), 0)
									END * ISNULL(m.ActualRate2, 0)) AS TurnOver
						FROM @MemList m
							INNER JOIN #AffTotal a ON m.AffId = a.AffId
							INNER JOIN bodb02.dbo.Bettrans b WITH (NOLOCK) ON m.IBCCustId = b.CustId
						WHERE DATEDIFF(m, @LastDay, @CurrDate) = 0
							AND b.WinlostDate = @CurrDate
							AND b.bettype IN (33, 43) --get HR only
							AND b.StatusID NOT IN (101, 102, 103, 121, 1)
						GROUP BY m.IbcCustId
							,m.AffId
					) a
					GROUP BY IBCCustID
						,AffID
					HAVING SUM(ISNULL(TurnOver, 0)) > @QmTurnOverHR
				) t
			GROUP BY t.AffID
		)
		SELECT 
			a.AffID
			,m.UserName
			,ISNULL(a.SPTotal, 0) 	AS SPQM
			,ISNULL(a.CSTotal, 0) 	AS CSQM
			,ISNULL(hr.Total, 0) 	AS HRQM
			,ISNULL(a.SPTotal, 0) + ISNULL(hr.Total, 0) + ISNULL(a.CSTotal, 0) AS TotalQM
			,a.RowIDX
		FROM #AffTotal a
			INNER JOIN @AffList m ON a.AffId = m.AffId
			LEFT JOIN HorseRacingQM hr ON a.AffID = hr.AffID
		ORDER BY a.RowIDX
	END
	
	SET @NRows = ISNULL(@NRows, 0)
END
GO
GRANT EXECUTE ON [dbo].[Aff_ReportQM] TO [bodbAdminNet]
GO