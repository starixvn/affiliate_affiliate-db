/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Sel]
	@PageId SMALLINT = NULL
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
*/

BEGIN
	SET NOCOUNT ON

	SELECT PageId, PageName, PageCode
	FROM dbo.LandingPage WITH (NOLOCK)
	WHERE IsDeleted = 0
		AND (@PageId IS NULL OR PageId = @PageId)
	ORDER BY PageId ASC
END
GO