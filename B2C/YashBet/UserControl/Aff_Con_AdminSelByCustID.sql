/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_AdminSelByCustID]
	@CustID INT
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task : Get user info
	Original: [Aff_Con_AdminSelByCustID]

	Revisions:
		--  DB03.bodb02 --> DB052.Affiliate_12BET
		-- VinhTrinh@20100507: Get closed field from affiliate_user instead of CustInfo 
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP for Affiliate_YashBet [RedmineID: #198909]
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