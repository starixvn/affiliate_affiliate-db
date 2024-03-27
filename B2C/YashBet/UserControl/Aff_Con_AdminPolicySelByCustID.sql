/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_AdminPolicySelByCustID]
	@CustID  INT,
	@GroupID INT = NULL OUTPUT
AS
/*	
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		- DB03.bodb02--> DB052.Affiliate_12BET
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP for Affiliate_YashBet [RedmineID: #198909]

*/
BEGIN
	SET NOCOUNT ON

	SELECT ac.UserName
	   ,fi.FuncName
	   ,fi.FuncDesc
	   ,mp.FuncId
	   ,mp.Policy
	   ,gp.Policy AS gpolicy
	   ,(ISNULL(mp.Policy, 0) | ISNULL(gp.Policy, 0)) & ISNULL(fi.FuncRender, 0) AS actual_policy
	   ,fi.ParentId
	   ,COUNT(fip.FuncId) AS subfunccount
	   ,fi.DisplayOrder
	FROM AffMemberPolicy mp WITH (NOLOCK)
		INNER JOIN Affiliate_User ac WITH (NOLOCK) ON ac.CustId = mp.CustId
		INNER JOIN AffFunctionInfo fi WITH (NOLOCK) ON mp.FuncId = fi.FuncId
		INNER JOIN AffGroupPolicy gp WITH (NOLOCK) ON gp.GroupId = ac.GroupId
													AND gp.FuncId = mp.FuncId
		LEFT JOIN AffFunctionInfo fip WITH (NOLOCK) ON fi.FuncId = fip.ParentId
													AND fip.ParentId <> fip.FuncId
	WHERE mp.CustId = @CustID
	GROUP BY ac.UserName
		,fi.FuncName
		,fi.FuncDesc
		,mp.FuncId
		,mp.Policy
		,fi.DisplayOrder
		,gp.Policy
		,fi.FuncRender
		,fi.ParentId
	ORDER BY fi.ParentId
		,COUNT(fip.FuncId) DESC
		,fi.DisplayOrder

	SELECT @GroupID = GroupId
	FROM Affiliate_User WITH (NOLOCK)
	WHERE CustId = @CustID

END
GO