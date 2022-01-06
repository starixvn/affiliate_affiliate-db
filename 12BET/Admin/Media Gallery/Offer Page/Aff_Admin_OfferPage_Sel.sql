/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_OfferPage_Sel]
	 @PageId	 INT = 0
	 ,@PageIndex INT = 1
	 ,@PageSize	 INT = 50
	 ,@Date		 DATETIME = NULL
	 ,@NRows	 INT = 0 OUTPUT
AS
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Offer Page - Select

	Revisions:
		- 20211213@Malcolm: Initialize SP [RedmineID: #165915]

	Param's Explanation:

*/

BEGIN
	
	SELECT @PageId = ISNULL(@PageId, 0)
	
	DECLARE @RowStart INT, @RowEnd INT
	SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	IF @PageId <> 0
	BEGIN
		SELECT ep.PageId, ep.FileName, ep.FileSize, ep.Language, ep.UploadDate, ep.EffectiveFromDate, ep.EffectiveToDate, n.NoOfAff AS [Affiliate]
		FROM dbo.OfferPage ep WITH(NOLOCK)
		OUTER APPLY (
			SELECT COUNT(1) AS [NoOfAff]
			FROM dbo.OfferAffiliate ea WITH(NOLOCK)
			WHERE ea.PageId = ep.PageId
		) n
		WHERE ep.PageId = @PageId
		RETURN
	END

	SELECT @NRows = COUNT(1) 
	FROM dbo.OfferPage ep WITH(NOLOCK)
	WHERE (@Date IS NULL OR (@Date BETWEEN ep.EffectiveFromDate AND ep.EffectiveToDate))

	IF @PageSize = 0
	BEGIN
		SELECT @RowStart = 1, @RowEnd = @NRows
	END

	SELECT n.PageId, n.FileName, n.FileSize, n.Language, n.UploadDate, n.EffectiveFromDate, n.EffectiveToDate, n.Affiliate
	FROM 
	(
		SELECT ep.PageId, ep.FileName, ep.FileSize, ep.Language, ep.UploadDate, ep.EffectiveFromDate, ep.EffectiveToDate, ISNULL(n.NoOfAff, 0) AS [Affiliate]
			,ROW_NUMBER() OVER(ORDER BY ep.PageId DESC) rn
		FROM dbo.OfferPage ep WITH(NOLOCK)
		OUTER APPLY (
			SELECT COUNT(1) AS [NoOfAff] FROM dbo.OfferAffiliate ea WITH(NOLOCK) 
			WHERE ea.PageId = ep.PageId 
		) as N (NoOfAff)
		WHERE (@Date IS NULL OR (@Date BETWEEN ep.EffectiveFromDate AND ep.EffectiveToDate)) 
	) AS n
	WHERE n.rn BETWEEN @RowStart AND @RowEnd
	ORDER BY n.rn ASC
	

END
GO
