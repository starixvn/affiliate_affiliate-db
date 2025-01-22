/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_GroupPolicySel]
	@Groupid int
AS 
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/
BEGIN
	SET NOCOUNT ON

	SELECT gp.CreateDate
	   ,gp.ModifyDate
	   ,gp.policy
	   ,gp.GroupId
	   ,fi.funcid
	   ,gi.GroupName
	   ,fi.funcname
	   ,fi.funcdesc
	   ,fi.parentid
	   ,COUNT(fip.funcID) AS SubFuncCount
	   ,fi.DisplayOrder
	FROM AffGroupPolicy gp WITH (NOLOCK)
		INNER JOIN AffGroupInfo gi WITH (NOLOCK) ON gp.GroupId = gi.GroupId
		INNER JOIN AffFunctionInfo fi WITH (NOLOCK) ON gp.funcid = fi.funcid
		LEFT JOIN AffFunctionInfo fip WITH (NOLOCK) ON fi.funcID = fip.ParentID
												AND fip.parentid <> fip.funcid
	WHERE gp.GroupId = @Groupid
	GROUP BY gp.CreateDate
		,gp.ModifyDate
		,gp.policy
		,gp.GroupId
		,fi.funcid
		,gi.GroupName
		,fi.funcname
		,fi.funcdesc
		,fi.parentid
		,fi.DisplayOrder
	ORDER BY fi.parentid, COUNT(fip.funcID) DESC, fi.DisplayOrder
END
GO