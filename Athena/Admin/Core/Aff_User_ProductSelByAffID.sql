/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_ProductSelByAffID]
	@AffID		INT
	,@MonthDate SMALLDATETIME = NULL
	,@Language	VARCHAR(10) = 'en-US'
AS

/*
	Created: 20090701@VinhTrinh	
	DB: DBAFF-Affiliate_Athena000

	Revisions:		
		- 20140522@Bobby: Update @MonthDate is all [current & history]
		- 20150512@Bobby: Correct @MonthDate to the end of the month day
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]
		- 20220602@Malcolm: remove products which have IsEnable = 0 [RedmineID: #172701]
*/

BEGIN
	SET @MonthDate = DATEADD(DAY, - 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0)) -- last day of month

	-- Get product setting
	DECLARE @ProductSetting TABLE (ProductId TINYINT)

	IF @MonthDate IS NULL OR DATEDIFF(MONTH, GETDATE(), @MonthDate) = 0 -- current month
		INSERT INTO @ProductSetting (ProductId)
		SELECT gs.ProductId
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.GroupSetting gs WITH (NOLOCK) ON ai.GroupId = gs.GroupId
		WHERE ai.AffId = @AffId

	IF @MonthDate IS NULL OR DATEDIFF(MONTH, GETDATE(), @MonthDate) < 0 -- history
		INSERT INTO @ProductSetting (ProductId)
		SELECT gsh.ProductId
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.GroupSettingHistory gsh WITH (NOLOCK) ON agh.GroupId = gsh.GroupId AND agh.MonthDate = gsh.MonthDate
		WHERE agh.AffId = @AffId
			AND (@MonthDate IS NULL OR agh.MonthDate = @MonthDate)

	-- Remove duplicate due to setting
	DELETE t
	FROM (
		SELECT ProductId, ROW_NUMBER() OVER(PARTITION BY ProductId ORDER BY (SELECT NULL)) AS RN FROM @ProductSetting
	) t
	WHERE RN > 1

	-- Return data
	SELECT p.ProductId, ISNULL(r.ResourceValue, p.ProductName) AS ProductName
	FROM dbo.Product p WITH (NOLOCK)
		INNER JOIN @ProductSetting ps ON p.ProductId = ps.ProductId
		LEFT JOIN dbo.RefResources r WITH (NOLOCK) ON r.ResourceKey = p.ProductName AND r.RefId = 'Product' AND r.LanguageCode = @Language
	WHERE p.IsEnabled = 1
END
GO