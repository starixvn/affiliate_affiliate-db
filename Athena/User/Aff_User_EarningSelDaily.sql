/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_EarningSelDaily]
	@AffId			INT
	,@ProductId		TINYINT			= 0
	,@monthdate		SMALLDATETIME	= NULL
	,@FromDate		SMALLDATETIME	= NULL
	,@ToDate		SMALLDATETIME	= NULL
	,@AffCurrency	VARCHAR(8)		= 'UUS' OUTPUT
AS

/*
	Created: 200900911@VinhTrinh 
	Task: [description of SP]  
	DB: DBAFF.Affiliate_Athena000

	Revisions:  		
		- Get data for daily report from table AffDaily instead of MemberDaily
		- 20100520@Johnny: apply StatusID in bettrans table
		- 20100930@Peter : Change the new formula for displayed winlost
				   Winlost on Aff site=Winlost-Odds Management - Marketing cost -  PSP
				   --The formula change since 1 Oct 2010--need to consider a new column MemWinlostFake on MemberDaily table if it is changed again
				   MemWinlostFake need to be updated on TaskMemberDaily
		- 20101228@Henry: change bettype to new range
		- 20130806@Jim:  just get Turnover value from  products that have group comm
		- 20140812@bobby.nguyen: update checking @monthdate
		- 20140819@bobby.nguyen: add column PlayerComm, PWin, PShare vs NetGaming
		- 20141226@bobby.nguyen: Enhance to check product which belongs to comm group setting or not
		- 20150126@bobby.nguyen: Check for having report data 
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]
		- 20220602@Malcolm: remove products which have IsEnable = 0 [RedmineID: #172701]

	Param's Explanation:  
		• @custid: affliate Id  
		• @monthdate: Month date need to view.
*/

BEGIN
	SET NOCOUNT ON

	IF @MonthDate IS NOT NULL AND (@FromDate IS NULL OR @ToDate IS NULL) -- get full month
	BEGIN
		SELECT @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0), @ToDate = @MonthDate
	END

	DECLARE @FromMonthDate SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0))
	DECLARE @ToMonthDate SMALLDATETIME = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0))

	DECLARE @ProductList TABLE (GroupProductId SMALLINT, ProductId SMALLINT, MonthDate SMALLDATETIME)

	IF DATEDIFF(MONTH, @ToMonthDate, GETDATE()) = 0 -- current month
		INSERT INTO @ProductList (GroupProductId, ProductId, MonthDate)
		SELECT DISTINCT ISNULL(g.GroupProductId, gs.ProductId), ISNULL(g.ProductId, gs.ProductId), @ToMonthDate
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.GroupSetting gs WITH (NOLOCK) ON ai.GroupId = gs.GroupId
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON gs.ProductId = g.GroupProductId
		WHERE ai.AffId = @AffId

	IF DATEDIFF(MONTH, @FromMonthDate, GETDATE()) > 0 -- history month
		INSERT INTO @ProductList (GroupProductId, ProductId, MonthDate)
		SELECT DISTINCT ISNULL(g.GroupProductId, gsh.ProductId), ISNULL(g.ProductId, gsh.ProductId), gsh.MonthDate
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.GroupSettingHistory gsh WITH (NOLOCK) ON agh.GroupId = gsh.GroupId AND agh.MonthDate = gsh.MonthDate
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON gsh.ProductId = g.GroupProductId
		WHERE agh.AffId = @AffId
			AND agh.MonthDate BETWEEN @FromMonthDate AND @ToMonthDate

	IF @ProductId > 0
		DELETE @ProductList WHERE GroupProductId <> @ProductId

	--Delete Products which have IsEnabled = 0
	DELETE p
	FROM @ProductList p
		INNER JOIN dbo.Product pr WITH(NOLOCK) ON pr.ProductID = p.ProductId
	WHERE pr.IsEnabled = 0

	-- Output AffCurrency
	SELECT @AffCurrency = e.CurrencyCode
	FROM dbo.AffInfo ai WITH(NOLOCK)
		INNER JOIN Currency e WITH(NOLOCK) ON e.CurrencyId = ai.Currency
	WHERE ai.AffId = @AffId

	DECLARE @PlaytechCasino SMALLINT = dbo.Aff_GetProductId ('Playtech Casino')

	-- Return data
	SELECT d.winlostdate
		,SUM(d.MemDeposit_aff) AS Deposit
		,SUM(d.MemWithdrawal_aff) AS Withdrawal
		,SUM(d.MemWinlost_aff) AS MemberWinlost
		,SUM(d.MemWinlostFake_aff) AS MemWinlostFake
		,SUM(d.MemBonus_aff) AS Bonus
		,SUM(d.MemAdjustment_aff) AS Adjustment
		,SUM(d.MemTurnover_aff) AS Turnover
		,SUM(d.MemPSP_aff) AS PSP
		,SUM(ISNULL(d.MemPlayerComm_aff, 0)) AS PlayerComm
		,SUM(CASE WHEN d.ProductID = @PlaytechCasino THEN ISNULL(d.PWin_aff, 0) ELSE 0 END) AS PWin
		,SUM(CASE WHEN d.ProductID = @PlaytechCasino THEN ISNULL(d.PShare_aff, 0) ELSE 0 END) AS PShare
		,SUM(CASE WHEN d.ProductID = @PlaytechCasino THEN (-d.MemWinlost_aff - d.PShare_aff) ELSE 0 END) AS NetGaming
	FROM dbo.AffDailySummary d WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON d.AffId = ai.AffId
		INNER JOIN @ProductList p ON d.ProductId = p.ProductId AND DATEDIFF(MONTH, d.Winlostdate, p.MonthDate) = 0
	WHERE d.AffID = @AffId
		AND d.winlostdate BETWEEN @fromdate	AND @todate
	GROUP BY d.winlostdate
	HAVING SUM(d.MemDeposit_aff) 		> 0
		OR SUM(d.MemWinlost_aff) 		<> 0
		OR SUM(d.MemBonus_aff) 			> 0
		OR SUM(d.MemAdjustment_aff) 	<> 0
		OR SUM(d.MemTurnover_aff) 		> 0
		OR SUM(ISNULL(d.MemPlayerComm_aff, 0)) > 0
	ORDER BY d.winlostdate
END
GO