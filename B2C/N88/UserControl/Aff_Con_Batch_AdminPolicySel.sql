/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_Batch_AdminPolicySel]
	@CustIDs nvarchar(4000),
	@GroupID int = NULL OUTPUT	
AS
/*
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G	
	Revisions:
		--DB03.bodb02 --> DB052.Affiliate_12BET
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		-- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
		- 20230912@Sally: Fix recursion 100 has been exhausted [RedmineID: #193867]
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