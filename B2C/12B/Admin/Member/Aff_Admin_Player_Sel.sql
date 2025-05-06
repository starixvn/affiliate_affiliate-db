/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Player_Sel]
	@CustId INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Home - Member
	
	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250507@Sally: Enhance Removed Player [RedmineID: #225717]


	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.RegisteredDate, ai.UserName AS AffUserName, mi.IsRemoved, mr.LastAction, ISNULL(mr.IsInclude, 1) AS IsInclude, mr.FromDate
	FROM dbo.MemberInfo mi WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffId = mi.AffId
	OUTER APPLY (
		SELECT TOP(1) mr.RemovedDate AS LastAction, mr.IsInclude, mr.FromDate
		FROM dbo.MemberRemoval mr WITH(NOLOCK)
		WHERE mr.CustId = mi.CustId 
		ORDER BY mr.RemovedDate DESC
	) AS mr
	WHERE mi.CustId = @CustId
END
GO