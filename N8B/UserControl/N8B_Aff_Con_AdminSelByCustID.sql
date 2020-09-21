/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
Alter PROCEDURE [dbo].[Aff_Con_AdminSelByCustID]
	@CustID int
AS
/*
Task : Get user info
DB: DBAFFN8B-Affiliate_N8B	

Original: [Aff_Con_AdminSelByCustID]
Revisions:
	--  DB03.bodb02 --> DB052.Affiliate_12BET
	-- VinhTrinh@20100507: Get closed field from affiliate_user instead of CustInfo 
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
*/
SET NOCOUNT ON
SELECT ac.custid,ac.username,ac.firstname,ac.lastname,ac.groupid, ac.roleid, ac.closed,ac.userpwd
FROM Affiliate_User ac with(nolock)	
WHERE	ac.custid=@custid

GO 