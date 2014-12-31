ALTER PROCEDURE [dbo].[Aff_PlayerSportsBookReport]
(
	@FromDate				DATE
	,@ToDate				DATE
	,@PreferedLanguage		VARCHAR(10)	= NULL
	,@IsGetAll				BIT 		= 0
	,@PageIndex				INT			= 1
	,@PageSize				INT			= 50
	,@NRows					INT			= 0 OUTPUT
)
AS
/*
Created:20141119@Bobby.Nguyen
Task: Get  SB Player Turnover Report
DB: DBAFFILIATE12BET/Affiliate_12Bet
Orgiginal: 

Revisions:    
	- 20141119@Bobby.Nguyen: Initial SP
*/   
BEGIN
	SET NOCOUNT ON
	
	IF(@FromDate > @ToDate) RETURN
	
	DECLARE @SportType	TINYINT	
		,@CurDate		DATE
		,@RptDate		DATE
	
	CREATE TABLE #MemberList
	(
		MemberId	INT
		,RowIDX		INT IDENTITY(1,1)
	)
	
	DECLARE @MemberPaging 
	AS TABLE (
		MemberId		INT
		,AffId			INT
		,UserName		VARCHAR(30)
		,IBCUserName	VARCHAR(30)
		,RowIDX			INT
	)
	
	SELECT @SportType	= dbo.Aff_GetSportID('SportsBook')
		,@CurDate		= GETDATE()
		,@RptDate		= '2009/01/01'
	
	SELECT @FromDate 	= CASE 
							WHEN @IsGetAll = 1 OR @FromDate <  @RptDate 
								THEN @RptDate 
							ELSE @FromDate 
						END
		, @ToDate 		= CASE WHEN @IsGetAll = 1 THEN @CurDate ELSE @ToDate END
	
	INSERT INTO #MemberList
	SELECT 
		md.IBCCustId
		
	FROM dbo.MemberDaily md WITH (NOLOCK)
	
		INNER JOIN dbo.MemberInfo mi WITH(NOLOCK)
		ON md.IBCCustID = mi.IBCCustID
		
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON mi.AffId = ai.AffId
		
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK)
		ON ai.AffId = ad.AffId
		
	WHERE (md.WinlostDate BETWEEN @FromDate AND @ToDate)
		AND (@PreferedLanguage IS NULL OR ad.PreferredLanguage = @PreferedLanguage)
		AND md.SportType = @SportType
		AND md.AffId > 0
		AND ai.STATUS	= 'Approved'

	GROUP BY md.IBCCustId
		,mi.UserName
	ORDER BY mi.UserName
	
	SET @NRows = @@ROWCOUNT
	
	IF(@NRows = 0) RETURN
	

	INSERT INTO @MemberPaging
	SELECT mi.IBCCustId
		, mi.AffID
		, mi.UserName
		, mi.IBCUserName
		, m.RowIDX
	FROM #MemberList m
		LEFT JOIN dbo.MemberInfo mi with(nolock)
		ON m.MemberId = mi.IBCCustId
		
	WHERE m.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY m.RowIDX
	
	DROP TABLE #MemberList

	-- get openning/closing balance info
	;WITH OpeningBalanceInfo (IBCCustId, OpeningBalance)
	AS (
		SELECT md.IBCCustId
			,md.OpeningBalance
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @MemberPaging p
			ON md.IBCCustId = p.MemberId
		WHERE md.WinlostDate = @FromDate
			AND md.SportType = @SportType
		

	), ClosingBalanceInfo (IBCCustId, ClosingBalance)
	AS (
		SELECT md.IBCCustId
			,md.ClosingBalance
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @MemberPaging p
			ON md.IBCCustId = p.MemberId
		WHERE md.WinlostDate = @ToDate
			AND md.SportType = @SportType	
	),SumWinLoss 
	AS (
		-- fetch final result
		SELECT md.IBCCustId
			,md.AffID
			----------------------------------------------
			,SUM(ISNULL(md.Deposit,0)) 		AS Deposit
			,SUM(ISNULL(md.Withdrawal,0)) 	AS Withdrawal
			,SUM(ISNULL(md.Bonus,0)) 		AS Bonus
			,SUM(ISNULL(md.Adjustment,0)) 	AS Adjustment
			,SUM(ISNULL(md.Turnover,0)) 	AS Turnover
			,SUM(ISNULL(md.DrawGame,0)) 	AS DrawGame
			,SUM(ISNULL(md.Turnover,0) - ISNULL(md.DrawGame,0))		
											AS NetTurnover
			,SUM(ISNULL(md.Outstanding,0)) 	AS Outstanding
			,SUM(ISNULL(md.Winlost,0)) 		AS WinLoss
		
		FROM dbo.MemberDaily md WITH (NOLOCK)
	
			INNER JOIN @MemberPaging p
			ON md.IBCCustId = p.MemberId

		
		WHERE (md.WinlostDate BETWEEN @FromDate AND @ToDate)
			AND md.SportType = @SportType
		
		GROUP BY md.IBCCustId
			,md.AffID
	)
	-- fetch final result
	SELECT p.MemberId AS IBCCustId
		,p.UserName
		,p.IBCUserName
		,p.AffID
		,ai.UserName 					AS AffUserName
		----------------------------------------------
		,ISNULL(s.Deposit,0) 		AS Deposit
		,ISNULL(s.Withdrawal,0) 	AS Withdrawal
		,ISNULL(s.Bonus,0) 			AS Bonus
		,ISNULL(s.Adjustment,0) 	AS Adjustment
		,ISNULL(s.Turnover,0) 		AS Turnover
		,ISNULL(s.DrawGame,0) 		AS DrawGame
		,ISNULL(s.NetTurnover,0)	AS NetTurnover
		,ISNULL(s.Outstanding,0) 	AS Outstanding
		,ISNULL(s.WinLoss,0) 		AS WinLoss
		
		,ISNULL(ob.OpeningBalance, 0) AS OpeningBalance
		,ISNULL(cb.ClosingBalance, 0) AS ClosingBalance
		---------------------------------------------
		,p.RowIDX
	
	FROM @MemberPaging p

		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON p.AffID	= ai.AffID
		
		LEFT JOIN SumWinLoss s
		ON p.MemberId = s.IBCCustId

		LEFT JOIN OpeningBalanceInfo ob
		ON p.MemberId = ob.IBCCustId
				
		LEFT JOIN ClosingBalanceInfo cb
		ON p.MemberId = cb.IBCCustId
		
	ORDER BY p.RowIDX

	RETURN
	
END
GO

GRANT EXECUTE ON [dbo].[Aff_PlayerSportsBookReport] TO [bodbAdminNet]
GO
/*
declare @NRows int
EXEC [Aff_PlayerSportsBookReport] 
	@FromDate				= '2014/11/01'
	,@ToDate				= '2014/11/02'
	,@NRows = @NRows OUTPUT
	,@pageindex = 1
	,@IsGetall = 1


select @NRows
*/