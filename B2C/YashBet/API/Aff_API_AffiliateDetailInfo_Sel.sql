/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_API_AffiliateDetailInfo_Sel]
	@PageIndex			INT = 1
	,@PageSize			INT = 50
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Get affiliate information

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
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
	FROM dbo.AffInfo a WITH(NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
		LEFT JOIN dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
	WHERE a.Status = 'Approved' AND a.IsRejected = 0
	ORDER BY a.UserName
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH FIRST @PageSize ROWS ONLY
END
GO