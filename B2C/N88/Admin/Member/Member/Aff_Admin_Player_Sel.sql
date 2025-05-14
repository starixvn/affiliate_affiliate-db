/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Player_Sel]
	@CustId INT
AS

/*
	Creator: 20220705@Malcolm
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Home - Member
	
	Revisions:
		- 20220705@Malcolm: Initialize SP [RedmineID: #173640]
		- 20250507@Sally: Enhance remooved Player [RedmineID: #224335]

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