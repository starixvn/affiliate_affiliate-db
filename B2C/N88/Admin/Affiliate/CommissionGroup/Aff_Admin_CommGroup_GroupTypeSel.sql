/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_CommGroup_GroupTypeSel]	
AS
/*
	Created: 20240424@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Calculate Revenue Share By Turnover [RedmineID: #203756]
	
	Revisions:
		- 20240424@Sally: Initialize SP [Redmine: #204177]
	
*/
BEGIN
	SET NOCOUNT ON;

	SELECT 	g.GroupTypeId 
		,g.GroupTypeBy 
		,g.GroupTypeName
		,g.DisplayOrder 
	FROM dbo.GroupType g WITH(NOLOCK)

END
