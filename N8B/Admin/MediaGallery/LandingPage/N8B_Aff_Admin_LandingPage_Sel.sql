/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Sel]
	@PageId SMALLINT = NULL
AS

/*
	Created: 20181001@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
		- 20191127@Percy: Sort by newest landing page [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	SELECT PageId, PageName, PageCode
	FROM dbo.LandingPage WITH (NOLOCK)
	WHERE IsDeleted = 0
		AND (@PageId IS NULL OR PageId = @PageId)
	ORDER BY PageId DESC
END
GO