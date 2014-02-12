Alter PROCEDURE [dbo].[Aff_Con_FuncInfoSel]
	
AS
/*DB03.BODB02--> DB052.Affiliate_ZZun */
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON

select acc.FuncId, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames, acc.parentid, count(acc1.funcID) as SubFuncCount,acc.System
from 
	AffFunctionInfo acc with (nolock)
	left join AffFunctionInfo acc1 with (nolock) on acc.funcID = acc1.ParentID and acc1.parentid <> acc1.funcid
where acc.[system] = 'AFFILIATE'
group by acc.FuncId, acc.parentid, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames,acc.System
order by acc.System,acc.parentid, SubFuncCount desc, acc.DisplayOrder
	--acc.FuncId


GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoSel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_FuncInfoSel] TO [bodbAdminNet]
GO