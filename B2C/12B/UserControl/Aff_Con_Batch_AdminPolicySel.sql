/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_Batch_AdminPolicySel]
	@CustIDs NVARCHAR(4000),
	@GroupID INT = NULL OUTPUT	
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @ListCust TABLE (CustId INT)

	-- Get info Cust input
	INSERT INTO  @ListCust (CustId)
	SELECT CONVERT(INT, val) AS CustId
	FROM dbo.Aff_f_StringSplit(@CustIDs,',')
	OPTION (MAXRECURSION 0)

	SELECT TOP 1 @GroupID = GroupID 
	FROM Affiliate_user u WITH(NOLOCK) 
		INNER JOIN @ListCust lc ON u.CustId = lc.CustId

	SELECT fi.FuncId
	   ,fi.FuncName
	   ,fi.FuncDesc
	   ,f.Policy
	   ,gp.Policy AS gpolicy
	   ,fi.ParentId
	   ,COUNT(fip.FuncId) AS SubFuncCount
	   ,fi.DisplayOrder
	FROM AffFunctionInfo fi WITH (NOLOCK)
	INNER JOIN (
		SELECT FuncId
		   ,MIN(policy) AS policy
		   ,ac.groupid AS groupid
		FROM AffMemberPolicy mp WITH (NOLOCK)
			INNER JOIN @ListCust lc ON mp.CustId = lc.CustId
			INNER JOIN Affiliate_User ac WITH (NOLOCK) ON ac.CustId = mp.CustId
		GROUP BY 
			mp.FuncId
			,ac.groupid
	)f ON fi.FuncId = f.FuncId
	INNER JOIN AffGroupPolicy gp WITH (NOLOCK) ON gp.groupid = f.groupid
												AND gp.FuncId = f.FuncId
	LEFT JOIN AffFunctionInfo fip WITH (NOLOCK) ON fi.FuncId = fip.ParentId
												AND fip.ParentId <> fip.FuncId
	GROUP BY 
		fi.FuncId
		,fi.FuncName
		,fi.FuncDesc
		,f.policy
		,gp.policy
		,fi.ParentId
		,fi.DisplayOrder
	ORDER BY fi.ParentId, COUNT(fip.FuncId) DESC, fi.DisplayOrder
END
GO