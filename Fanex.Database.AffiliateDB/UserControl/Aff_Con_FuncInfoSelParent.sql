ALTER PROCEDURE [dbo].[Aff_Con_FuncInfoSelParent]
AS
/*DB03.BODB02 --> DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
	Select FuncId, FuncName
	from AffFunctionInfo
	where FuncId = ParentId AND System = 'AFFILIATE'


GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoSelParent] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Aff_Con_FuncInfoSelParent] TO [bodbAdminNet]