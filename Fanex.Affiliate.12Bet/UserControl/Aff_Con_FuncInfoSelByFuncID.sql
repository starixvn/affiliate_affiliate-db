ALTER PROCEDURE [dbo].[Aff_Con_FuncInfoSelByFuncID]
	@FuncId int
AS
/*DB03.BODB02--> Affiliate_12BET*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
SET NOCOUNT ON
select FuncId, FuncName, FuncDesc, FileNames, (select count(funcid) from AffFunctionInfo acc1 with (nolock) where acc1.parentid = acc.funcid and acc1.parentid <> acc1.funcid) as SubFuncCount
from AffFunctionInfo acc with (nolock)
where FuncId = @FuncId


GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoSelByFuncID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_FuncInfoSelByFuncID] TO [bodbAdminNet]
GO