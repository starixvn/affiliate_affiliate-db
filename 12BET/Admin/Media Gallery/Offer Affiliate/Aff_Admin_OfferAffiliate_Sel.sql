/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_OfferAffiliate_Sel]
	 @UserId INT
	 ,@AffName NVARCHAR(50) = ''
	 ,@FileName NVARCHAR(250) = ''
	 ,@PageIndex INT = 1
	 ,@PageSize	 INT = 50
	 ,@NRows	 INT = 0 OUTPUT
AS
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Offer Affiliate - Select

	Revisions:
		- 20211213@Malcolm: Initialize SP [RedmineID: #165915]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @RowStart INT, @RowEnd INT
	SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT @AffName = ISNULL(@AffName, ''), @FileName = ISNULL(@FileName, '')

	SELECT @NRows = COUNT(1)
	FROM dbo.OfferAffiliate ea WITH(NOLOCK)
		INNER JOIN dbo.OfferPage ep WITH(NOLOCK) ON ep.PageId = ea.PageId
		INNER JOIN dbo.AffDetail d WITH(NOLOCK) ON d.AffID = ea.AffId 
		INNER JOIN dbo.UserMarket m WITH(NOLOCK) ON m.MarketId = d.PreferredLanguage
	WHERE (d.UserName LIKE '%' + @AffName + '%' AND ep.FileName LIKE '%' + @FileName + '%') AND m.CustId = @UserId

	SELECT n.AffId, n.UserName, n.PageId, n.FileName, n.EffectiveFromDate, n.EffectiveToDate
	FROM 
	(
		SELECT ea.AffId, d.UserName, ea.PageId, ep.FileName, ep.EffectiveFromDate, ep.EffectiveToDate, ROW_NUMBER() OVER(ORDER BY d.Username ASC) AS rn
		FROM dbo.OfferAffiliate ea WITH(NOLOCK)
			INNER JOIN dbo.OfferPage ep WITH(NOLOCK) ON ep.PageId = ea.PageId
			INNER JOIN dbo.AffDetail d WITH(NOLOCK) ON D.AffID = ea.AffId 
			INNER JOIN dbo.UserMarket m WITH(NOLOCK) ON m.MarketId = d.PreferredLanguage
		WHERE (d.UserName LIKE '%' + @AffName + '%' AND ep.FileName LIKE '%' + @FileName + '%') AND m.CustId = @UserId
	) AS n
	WHERE n.rn BETWEEN @RowStart AND @RowEnd 
	ORDER BY n.rn ASC

END
GO
