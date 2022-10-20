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
		- 20191127@Percy: Sort by newest landing page [RedmineID: #118992]
		- 20221020@Eddie: Change order of Exchange & Sportsbook [RedmineID: #179392]
*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_LandingPage AS (  
		SELECT 
		PageId
		,PageName
		,PageCode  
		,CASE PageName WHEN 'Sportsbook' THEN 1
					   WHEN 'Exchange'   THEN 3
					   ELSE 2 END AS TypeID  
	    FROM dbo.LandingPage WITH (NOLOCK)  
		WHERE IsDeleted = 0 AND (@PageId IS NULL OR PageId = @PageId)    
	)  
	SELECT PageId, PageName, PageCode    
	FROM CTE_LandingPage  
	ORDER BY TypeID, PageId DESC
END
GO