/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Deal_GroupType_Sel]	
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Operation - Deal - Dropdown DealType
	
	Revisions:
		- 20250526@Lewis: Initialize SP [Redmine: #228530]
	
*/
BEGIN
	SET NOCOUNT ON;

	SELECT 	g.GroupTypeId 
		,g.GroupTypeBy 
		,g.GroupTypeName
	FROM dbo.GroupType g WITH(NOLOCK)
	WHERE g.IsEnabled = 1

END
