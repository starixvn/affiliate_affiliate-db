ALTER PROCEDURE [dbo].[Aff_ReportQM] 
	@AffName VARCHAR(50) = NULL
	,@PreferredLanguage VARCHAR(11) = NULL
	,@Month INT
	,@Year INT
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*
Created: 20091213@Peter
Task : Get Qualifying member report for all affiliates.
DB: DB052.Affiliate_12BET
Original: 
Revisions:
	- 20110523@Henry: change bettype to new range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120508@Johnny: Add Casino 
	- 20120606@Peter : Exclude waiting tickets
	- 20140403@Bobby:  exclude Keno product & other sports

Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT
		,@CasinoID INT
		,@MaxWinlostDate SMALLDATETIME
		,@NoComGroupID INT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')
		,@CasinoID = dbo.Aff_GetSportID('Casino')

	SELECT @FirstDay = cast(cast(@Year AS VARCHAR(5)) + '-' + cast(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)

	--Get last day of inputted month
	SELECT @LastDay = DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))

	SELECT @MaxWinlostDate = max(WinlostDate)
	FROM AffCommission WITH (NOLOCK)

	SELECT @NoComGroupID = GroupID
	FROM CommGroup WITH (NOLOCK)
	WHERE GroupName = 'NoCommission'

	SELECT @AffName = '%' + Coalesce(@AffName, '') + '%'

	SELECT @NRows = count(1)
	FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK)
		ON ai.AffId = ad.AffId
	WHERE ai.Username LIKE @AffName
		AND isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
		AND ai.ApprovedDate < @LastDay
		--Exclude all closed affs 
		AND (
			ai.IsClosed = 0
			OR ai.GroupID <> @NoComGroupID
			)
		AND ai.STATUS = 'approved'

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	DECLARE @TempAff TABLE (
		AffId INT PRIMARY KEY
		,UserName NVARCHAR(30)
		)

	INSERT INTO @TempAff
	SELECT m.AffId
		,m.username
	FROM (
		SELECT ROW_NUMBER() OVER (
				ORDER BY ai.AffId
				) AS TheCount
			,ai.AffID
			,ai.UserName
			,ad.PreferredLanguage
		FROM AffInfo ai WITH (NOLOCK)
			INNER JOIN AffDetail ad WITH (NOLOCK)
			ON ai.AffId = ad.AffId
		WHERE ai.STATUS = 'Approved'
			AND ai.ApprovedDate < @LastDay
			--Exclude all closed affs 
			AND (
				ai.IsClosed = 0
				OR ai.GroupID <> @NoComGroupID
				)
			AND ai.Username LIKE @AffName
			AND isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
		) m
	WHERE m.TheCount BETWEEN @RowStart AND @RowEnd

	IF (@LastDay <= @MaxWinlostDate) --Get Data from AffCommission
	BEGIN
		SELECT a.AffID
			,a.username AS username
			,Sum(isnull(m.SPQM, 0)) AS SPQM
			,Sum(isnull(m.HRQM, 0)) AS HRQm
			,Sum(isnull(m.CAQM, 0)) AS CAQM
			,Sum(isnull(m.SPQM, 0) + isnull(m.HRQM, 0) + isnull(m.CAQM, 0)) AS TotalQM
		FROM @TempAff a
			LEFT JOIN (
			SELECT AffId
				,isnull(QualifiedMember, 0) AS SPQM
				,0 AS HRQM
				,0 AS CAQM
			FROM AffCommission WITH (NOLOCK)
			WHERE WinlostDate = @LastDay
				AND SportID = @SportsBookID
			
			UNION ALL
			SELECT AffId
				,0 AS SPQM
				,isnull(QualifiedMember, 0) AS HRQM
				,0 AS CAQM
			FROM AffCommission WITH (NOLOCK)
			WHERE WinlostDate = @LastDay
				AND SportID = @HorseRacingID
			
			UNION ALL
			SELECT AffId
				,0 AS SPQM
				,0 AS HRQM
				,isnull(QualifiedMember, 0) AS CAQM
			FROM AffCommission WITH (NOLOCK)
			WHERE WinlostDate = @LastDay
				AND SportID = @CasinoID
			) m
			ON m.AffID = a.AffID
		GROUP BY a.AffID
			,a.username
		ORDER BY a.AffId
	END
	ELSE --Calculate data for uncalculated month
	BEGIN
		DECLARE @MemList TABLE (
			IBCCustId INT
			,AffId INT
			,ActualRate2 FLOAT
			)
		DECLARE @QmTurnOverSP MONEY
			,@QmTurnOverHR MONEY
			,@QmTurnOverCA MONEY
			,@QMDepositCA MONEY
			,@CurrDate SMALLDATETIME

		SELECT @CurrDate = convert(VARCHAR(10), current_timestamp, 120)
			,@LastDay = (CASE 
				WHEN @LastDay >= @CurrDate THEN dateadd(d, - 1, @CurrDate)
				ELSE @LastDay END
				)

		SELECT @QmTurnOverSP = QMTurnOver
		FROM SportType(NOLOCK)
		WHERE SportID = @SportsBookID

		SELECT @QmTurnOverHR = QMTurnOver
		FROM SportType(NOLOCK)
		WHERE SportID = @HorseRacingID

		SELECT @QmTurnOverCA = QMTurnOver
			,@QMDepositCA = QMDeposit
		FROM SportType(NOLOCK)
		WHERE SportID = @CasinoID

		IF (@FirstDay > @CurrDate) --The month is incorrect
		BEGIN
			SELECT AffID
				,username
				,0 AS SPQM
				,0 AS HRQm
				,0 AS CAQm
				,0 AS TotalQM
			FROM @TempAff

			RETURN
		END

		INSERT INTO @MemList
		SELECT IbcCustId
			,mi.AffId
			,ActualRate2
		FROM MemberInfo mi WITH (NOLOCK)
			INNER JOIN @TempAff a
			ON mi.AffId = a.AffId
			INNER JOIN Exchange_Current e WITH (NOLOCK)
			ON mi.Currency = e.ExchangeId
		WHERE mi.IsRemoved = 0

		--Calculate Turnover for SP & HR & CA
		SELECT a.AffID
			,a.username AS username
			,isnull(sp.TotalQM, 0) AS SPQM
			,isnull(hr.TotalQM, 0) AS HRQm
			,isnull(ca.TotalQM, 0) AS CAQm
			,isnull(sp.TotalQM, 0) + isnull(hr.TotalQM, 0) + isnull(ca.TotalQM, 0) AS TotalQM
		FROM @TempAff a
			LEFT JOIN (
			SELECT t.AffID AS AffID
				,sum(CASE 
						WHEN t.TurnOver >= @QmTurnOverSP THEN 1
						ELSE 0
						END) AS TotalQM
			FROM (
				SELECT IBCCustID
					,AffID
					,sum(isnull(TurnOver, 0)) AS TurnOver
				FROM (
					SELECT IBCCustID
						,AffID --Get data from MemberDaily for SP
						,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
					FROM MemberDaily md(NOLOCK)
					WHERE WinlostDate BETWEEN @FirstDay AND @LastDay
						AND SportType = @SportsBookID
						AND AffID IN (
							SELECT AffID
							FROM @TempAff
							)
					GROUP BY IBCCustID
						,AffID
					
					UNION ALL
					SELECT m.IbcCustId
						,m.AffId --Get data from bettrans for SP
						,Sum(isnull(abs(b.stake), 0) * isnull(m.ActualRate2, 0)) AS TurnOver
					FROM @MemList m
						INNER JOIN bodb02.dbo.Bettrans b WITH (NOLOCK)
						ON m.IBCCustId = b.CustId
					WHERE datediff(m, @LastDay, @CurrDate) = 0
						AND b.WinlostDate = @CurrDate
						AND (
							b.bettype <= 999
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
				) t
			GROUP BY t.AffID
			) sp
			ON sp.AffID = a.AffID
			LEFT JOIN (
			SELECT t.AffID AS AffID
				,sum(CASE 
						WHEN t.TurnOver >= @QmTurnOverHR THEN 1
						ELSE 0
						END) AS TotalQM
			FROM (
				SELECT IBCCustID
					,AffID
					,sum(isnull(TurnOver, 0)) AS TurnOver
				FROM (
					SELECT IBCCustID
						,AffID --Get data from MemberDaily for HR
						,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
					FROM MemberDaily md(NOLOCK)
					WHERE WinlostDate BETWEEN @FirstDay AND @LastDay
						AND SportType = @HorseRacingID
						AND AffID IN (
							SELECT AffID
							FROM @TempAff
							)
					GROUP BY IBCCustID
						,AffID
					
					UNION ALL
					SELECT m.IbcCustId
						,m.AffId --Get data from bettrans for HR
						,Sum(CASE 
								WHEN bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2
								ELSE isnull(abs(stake), 0)
								END * isnull(m.ActualRate2, 0)) AS TurnOver
					FROM @MemList m
						INNER JOIN bodb02.dbo.Bettrans b WITH (NOLOCK)
						ON m.IBCCustId = b.CustId
					WHERE datediff(m, @LastDay, @CurrDate) = 0
						AND b.WinlostDate = @CurrDate
						AND (
							b.bettype <= 999
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
				) t
			GROUP BY t.AffID
			) hr
			ON hr.AffID = a.AffID
			LEFT JOIN (
			SELECT t.AffID AS AffID
				,sum(CASE 
						WHEN t.TurnOver >= @QmTurnOverCA
							AND t.Deposit >= @QMDepositCA THEN 1
						ELSE 0
						END) AS TotalQM
			FROM (
				SELECT IBCCustID
					,AffID --Get data from MemberDaily for HR
					,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS TurnOver
					,sum(isnull(Deposit, 0) * isnull(AffExRate, 1)) AS Deposit
				FROM MemberDaily md(NOLOCK)
				WHERE WinlostDate BETWEEN @FirstDay AND @LastDay
					AND SportType = @CasinoID
					AND AffID IN (
						SELECT AffID
						FROM @TempAff
						)
				GROUP BY IBCCustID
					,AffID
				) t
			GROUP BY t.AffID
			) ca
			ON ca.AffID = a.AffID
		ORDER BY a.AffId
	END
END
GO

GRANT EXECUTE ON [dbo].[Aff_ReportQM] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_ReportQM] TO [VNTeam]
