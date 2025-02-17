/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_API_AffiliateDetailInfo_Sel]
	@PageIndex			INT = 1
	,@PageSize			INT = 50
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Get affiliate information

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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
		,CASE WHEN a.IsRejected = 0 THEN a.Status ELSE 'Suspended' END AS Status 
		,a.Email
		,ad.Player_CustId
		,a.AffId
	FROM dbo.AffInfo a WITH(NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
		LEFT JOIN dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
	WHERE a.Status = 'Approved' --AND a.IsRejected = 0
	ORDER BY a.UserName
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH FIRST @PageSize ROWS ONLY
END
GO