/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_EarningSelDetail]
	@AffId			INT			= 0
	,@ProductId		TINYINT		= 0
	,@MonthDate		SMALLDATETIME
	,@AffCurrency	VARCHAR(8)	= 'UUS' OUTPUT
AS
/*
	Created: 200900911@VinhTrinh
	Task : [description of SP]  
	DB: DB052.Affiliate_ZZun
	Revisions:  		
	    - addition Prefix info
		- 20140812@bobby.nguyen: re-format code & adding Currency into result output
		- 20140819@bobby.nguyen: add column PlayerComm, PWin, PShare vs NetGaming
		- 20141226@bobby.nguyen: Enhance to check product which belongs to comm group setting or not
		- 20150126@bobby.nguyen: Check for having report data 
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]
		- 20220602@Malcolm: remove products which have IsEnable = 0 [RedmineID: #172701]
	
	Param's Explanation:  
	• @AffId affliate Id  
	• @MonthDate Month date need to view.  
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	DECLARE @ProductList TABLE (GroupProductId SMALLINT, ProductId SMALLINT)

	IF DATEDIFF(MONTH, @MonthDate, GETDATE()) = 0 -- current month
		INSERT INTO @ProductList (GroupProductId, ProductId)
		SELECT DISTINCT ISNULL(g.GroupProductId, gs.ProductId), ISNULL(g.ProductId, gs.ProductId)
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.GroupSetting gs WITH (NOLOCK) ON ai.GroupId = gs.GroupId
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON gs.ProductId = g.GroupProductId
		WHERE ai.AffId = @AffId

	IF DATEDIFF(MONTH, @MonthDate, GETDATE()) > 0 -- history month
		INSERT INTO @ProductList (GroupProductId, ProductId)
		SELECT DISTINCT ISNULL(g.GroupProductId, gsh.ProductId), ISNULL(g.ProductId, gsh.ProductId)
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.GroupSettingHistory gsh WITH (NOLOCK) ON agh.GroupId = gsh.GroupId AND agh.MonthDate = gsh.MonthDate
			LEFT JOIN dbo.Aff_f_GroupProduct() g ON gsh.ProductId = g.GroupProductId
		WHERE agh.AffId = @AffId
			AND agh.MonthDate = @EndOfMonth

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

	DECLARE @PlaytechCasino	SMALLINT = dbo.Aff_GetProductId ('Playtech Casino')

	-- Return data
	SELECT 
		m.UserName
		,m.Currency
		,ISNULL(SUM(d.Winlost * AffExRate), 0) AS winlost
		,ISNULL(SUM(d.Deposit * AffExRate), 0) AS Deposit
		,ISNULL(SUM(d.Withdrawal * AffExRate), 0) AS Withdrawal
		,ISNULL(SUM(d.Bonus * AffExRate), 0) AS Bonus
		,ISNULL(SUM(d.Turnover * AffExRate), 0) AS Turnover
		,ISNULL(SUM(d.Adjustment * AffExRate), 0) AS Adjustment
		,ISNULL(SUM(d.PSP * AffExRate), 0) AS PSP
		,SUM(ISNULL(d.PlayerComm, 0) * AffExRate) AS PlayerComm
		,SUM(CASE WHEN d.ProductID = @PlaytechCasino THEN (ISNULL(d.PWin, 0) * AffExRate) ELSE 0 END ) PWin
		,SUM(CASE WHEN d.ProductID = @PlaytechCasino THEN (ISNULL(d.PShare, 0) * AffExRate) ELSE 0 END ) PShare
		,SUM(CASE WHEN d.ProductID = @PlaytechCasino THEN ((-ISNULL(d.Winlost, 0) -ISNULL(d.PShare, 0)) * AffExRate) ELSE 0 END ) NetGaming
	FROM dbo.MemberDaily d WITH (NOLOCK)
		INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON m.UserName = d.UserName
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON d.AffId = ai.AffId
		INNER JOIN @ProductList p ON d.ProductId = p.ProductId
	WHERE d.AffID = @AffID
		AND d.winlostdate = @MonthDate
	GROUP BY m.UserName
		,m.Currency
	HAVING ISNULL(SUM(d.Winlost * AffExRate), 0) 		<> 0
		OR ISNULL(SUM(d.Deposit * AffExRate), 0) 		> 0
		OR ISNULL(SUM(d.Bonus * AffExRate), 0) 			> 0
		OR ISNULL(SUM(d.Turnover * AffExRate), 0) 		> 0
		OR ISNULL(SUM(d.Adjustment * AffExRate), 0) 	<> 0
		OR SUM(ISNULL(d.PlayerComm, 0) * AffExRate) 	> 0
END
GO