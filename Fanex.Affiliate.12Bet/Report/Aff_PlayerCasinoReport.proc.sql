/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_PlayerCasinoReport]
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
Created:20141119@Bobby.Nguyen
Task: Get  SB Player Turnover Report
DB: DBAFFILIATE12BET/Affiliate_12Bet
Orgiginal: 

Revisions:    
	- 20141119@Bobby.Nguyen: Initial SP
	- 20150827@Bobby.Nguyen: Convert to base currency US$
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
		,UserName		VARCHAR(30)
		,IBCUserName	VARCHAR(30)
		,RegisteredDate	DATETIME
		,RowIDX			INT
	)
	
	SELECT @SportType	= dbo.Aff_GetSportID('Casino')
		,@CurDate		= GETDATE()
		,@RptDate		= '2014/06/01'
	
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
		, mi.UserName
		, mi.IBCUserName
		, mi.RegisteredDate
		, m.RowIDX
	FROM #MemberList m
		LEFT JOIN dbo.MemberInfo mi with(nolock)
		ON m.MemberId = mi.IBCCustId
		
	WHERE m.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY m.RowIDX
	
	DROP TABLE #MemberList

	-- fetch final result
	SELECT 
		p.RowIDX
		,md.IBCCustId
		,p.UserName
		,p.IBCUserName
		,p.RegisteredDate
		,md.AffID
		,ai.UserName 					AS AffUserName
	
		----------------------------------------------
		,SUM(ISNULL(md.Turnover,0) * ISNULL(AffExRate, 1)) 	AS Turnover
		,SUM(ISNULL(md.Winlost,0) * ISNULL(AffExRate, 1)) 	AS WinLoss
		,SUM(ISNULL(md.Deposit,0) * ISNULL(AffExRate, 1)) 	AS Deposit
		,SUM(ISNULL(md.Bonus,0) * ISNULL(AffExRate, 1)) 	AS Bonus
	
	FROM dbo.MemberDaily md WITH (NOLOCK)
	
		INNER JOIN @MemberPaging p
		ON md.IBCCustId = p.MemberId

		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON md.AffID	= ai.AffID
		
	WHERE (md.WinlostDate BETWEEN @FromDate AND @ToDate)
		AND md.SportType = @SportType
		
	GROUP BY 	
		p.RowIDX
		,md.IBCCustId
		,p.UserName
		,p.IBCUserName
		,p.RegisteredDate
		,md.AffID
		,ai.UserName
		
	ORDER BY p.RowIDX
END
GO
