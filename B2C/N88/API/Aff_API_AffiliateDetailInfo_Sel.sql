/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_API_AffiliateDetailInfo_Sel]
	@PageIndex			INT = 1
	,@PageSize			INT = 50
AS

/*
	Created: 20221031@Malcolm
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Get affiliate information

	Revisions:
		- 20221031@Malcolm: Initialize SP [RedmineID: #177552]
		- 20240930@Sally: Enhance API sync affiliate information - Return more column info [RedmineID: #211533]
*/
BEGIN
	SET NOCOUNT ON

	SELECT 
		p.UserName AS ParentAff
		,a.UserName
		,a.AffCode
		,a.CurrencyCode
		,a.RegisteredDate
		,ad.LastLoginDate
		,ad.LastLoginIP
		,ad.Player_Username
		,a.FirstName
		,a.LastName
		,ad.Phone
		,a.Status 
		,a.Email
	FROM dbo.AffInfo a WITH(NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
		LEFT JOIN dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
	WHERE a.Status = 'Approved' AND a.IsRejected = 0
	ORDER BY a.UserName
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH FIRST @PageSize ROWS ONLY
END
GO