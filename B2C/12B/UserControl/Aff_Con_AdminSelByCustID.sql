/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_AdminSelByCustID]
	@CustID INT
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task : Get user info

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/
BEGIN
	SET NOCOUNT ON

	SELECT
		ac.CustId
	   ,ac.UserName
	   ,ac.FirstName
	   ,ac.LastName
	   ,ac.GroupId
	   ,ac.RoleId
	   ,ac.Closed
	   ,ac.UserPwd
	FROM Affiliate_User ac WITH (NOLOCK)
	WHERE ac.CustId = @CustID
END
GO