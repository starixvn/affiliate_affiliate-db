/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20201229@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: User permission control - Set view to Exe. Marketing (role = 4) on Signup Member function (funcId = 17)
*/

use Affiliate_12BET
go

update dbo.RoleFunction with (rowlock)
set Policy = 1
where RoleId = 4 and FuncId = 17