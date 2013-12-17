ALTER Procedure [dbo].[AffAdmin_Con_SelByCustID]
	@CustID int
AS
/*
Task : Get user info
DB: DB03.bodb02 --> DB052.Affiliate_MYM
Original: [Aff_Con_AdminSelByCustID]
Revisions:
	- VinhTrinh@20100507: Get closed field from AdminUser instead of CustInfo 
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON
SELECT ac.custid,ac.username,ac.firstname,ac.lastname,ac.groupid, ac.roleid, ac.closed,ac.userpwd
FROM AdminUser ac with(nolock)	
WHERE	ac.custid=@custid
