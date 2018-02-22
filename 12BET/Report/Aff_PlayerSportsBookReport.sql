/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_PlayerSportsBookReport]
(
	@Username				NVARCHAR(50) = NULL
	,@FromDate				DATE
	,@ToDate				DATE
	,@PreferedLanguage		VARCHAR(10)	= NULL
	,@IsGetAll				BIT 		= 0
	,@PageIndex				INT			= 1
	,@PageSize				INT			= 50
	,@NRows					INT			= 0 OUTPUT
)
AS

/*
	Created: 20141119@Bobby
	Task: Get SB Player Turnover Report
	DB: DBAFF12BET.Affiliate_12Bet
	Orgiginal: 

	Revisions:    
		- 20141119@Bobby: Initial SP
		- 20150827@Bobby: Convert to base currency US$
		- 20170411@Percy: Support search by Affiliate name [RedmineID: #74588]
		- 20171109@Percy: Support sort member's username [RedmineID: #86353]
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
		,RowIDX		INT
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
	
	INSERT INTO #MemberList (MemberId, RowIDX)
	SELECT mi.IBCCustId, ROW_NUMBER() OVER(ORDER BY mi.UserName)
	FROM dbo.MemberInfo mi WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE
		EXISTS (
			SELECT 1
			FROM dbo.MemberDaily md WITH (NOLOCK)
			WHERE md.IBCCustID = mi.IBCCustID
			AND (md.WinlostDate BETWEEN @FromDate AND @ToDate)
			AND md.SportType = @SportType
			AND md.AffId > 0
		)
		AND (@PreferedLanguage IS NULL OR ad.PreferredLanguage = @PreferedLanguage)
		AND ai.STATUS	= 'Approved'
		AND ai.UserName LIKE '%' + ISNULL(@Username, '') + '%'
	
	SET @NRows = @@ROWCOUNT
	
	IF(@NRows = 0) RETURN

	INSERT INTO @MemberPaging
	SELECT mi.IBCCustId
		, mi.AffID
		, mi.UserName
		, mi.IBCUserName
		, m.RowIDX
	FROM #MemberList m
		LEFT JOIN dbo.MemberInfo mi WITH(NOLOCK) ON m.MemberId = mi.IBCCustId
	WHERE m.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY m.RowIDX
	
	DROP TABLE #MemberList

	-- get openning/closing balance info
	;WITH OpeningBalanceInfo (IBCCustId, OpeningBalance)
	AS (
		SELECT md.IBCCustId
			,(md.OpeningBalance  * ISNULL(AffExRate, 1)) AS OpeningBalance
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @MemberPaging p ON md.IBCCustId = p.MemberId
		WHERE md.WinlostDate = @FromDate
			AND md.SportType = @SportType

	)
	, ClosingBalanceInfo (IBCCustId, ClosingBalance)
	AS (
		SELECT md.IBCCustId
			,(md.ClosingBalance * ISNULL(AffExRate, 1)) AS ClosingBalance
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @MemberPaging p ON md.IBCCustId = p.MemberId
		WHERE md.WinlostDate = @ToDate
			AND md.SportType = @SportType	
	)
	,SumWinLoss 
	AS (
		-- fetch final result
		SELECT md.IBCCustId
			,md.AffID
			----------------------------------------------
			,SUM(ISNULL(md.Deposit,0) * ISNULL(AffExRate, 1)) 		AS Deposit
			,SUM(ISNULL(md.Withdrawal,0) * ISNULL(AffExRate, 1)) 	AS Withdrawal
			,SUM(ISNULL(md.Bonus,0) * ISNULL(AffExRate, 1)) 		AS Bonus
			,SUM(ISNULL(md.Adjustment,0) * ISNULL(AffExRate, 1)) 	AS Adjustment
			,SUM(ISNULL(md.Turnover,0) * ISNULL(AffExRate, 1)) 		AS Turnover
			,SUM(ISNULL(md.DrawGame,0) * ISNULL(AffExRate, 1)) 		AS DrawGame
			,SUM((ISNULL(md.Turnover,0) - ISNULL(md.DrawGame,0)) 
						* ISNULL(AffExRate, 1))						AS NetTurnover
			,SUM(ISNULL(md.Outstanding,0) * ISNULL(AffExRate, 1)) 	AS Outstanding
			,SUM(ISNULL(md.Winlost,0) * ISNULL(AffExRate, 1)) 		AS WinLoss
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @MemberPaging p ON md.IBCCustId = p.MemberId
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
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON p.AffID	= ai.AffID
		LEFT JOIN SumWinLoss s ON p.MemberId = s.IBCCustId
		LEFT JOIN OpeningBalanceInfo ob ON p.MemberId = ob.IBCCustId
		LEFT JOIN ClosingBalanceInfo cb ON p.MemberId = cb.IBCCustId
	ORDER BY p.RowIDX
END
GO