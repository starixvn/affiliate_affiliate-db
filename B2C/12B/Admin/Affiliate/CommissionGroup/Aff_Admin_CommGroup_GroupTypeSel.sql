/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_CommGroup_GroupTypeSel]	
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Calculate Revenue Share By Turnover
	
	Revisions:
		- 20241118@Eddie: Initialize SP [Redmine: #212201]
		- 20250526@Lewis: Add IsEnabled = 1 [RedmineID: #228530]
	
*/
BEGIN
	SET NOCOUNT ON;

	SELECT 	g.GroupTypeId 
		,g.GroupTypeBy 
		,g.GroupTypeName
	FROM dbo.GroupType g WITH(NOLOCK)
	WHERE g.IsEnabled = 1

END
