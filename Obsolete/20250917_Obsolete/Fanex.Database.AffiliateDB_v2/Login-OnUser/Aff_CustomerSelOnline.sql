 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Aff_CustomerSelOnline]
	@custid int
AS
/*
Created: 20090122@Peter
Task : Select customer online list
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation:
• @userid: customer id
*/

SET NOCOUNT ON

SELECT * FROM on_user (nolock)
WHERE custid = @custid
ORDER BY on_userid


GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelOnline] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelOnline] TO [VNTeam] 