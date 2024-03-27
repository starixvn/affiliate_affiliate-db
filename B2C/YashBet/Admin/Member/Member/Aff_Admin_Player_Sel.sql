/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Player_Sel]
	@CustId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Home - Member
	
	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.RegisteredDate, ai.UserName AS AffUserName, mi.IsRemoved, mr.LastAction, ISNULL(mr.IsInclude, 1) AS IsInclude
	FROM dbo.MemberInfo mi WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffId = mi.AffId
	OUTER APPLY (
		SELECT TOP(1) mr.RemovedDate AS LastAction, mr.IsInclude
		FROM dbo.MemberRemoval mr WITH(NOLOCK)
		WHERE mr.CustId = mi.CustId 
		ORDER BY mr.RemovedDate DESC
	) AS mr
	WHERE mi.CustId = @CustId
END
GO