/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_FuncInfoSelByFuncID]
	@FuncId int
AS
/*
DB: DBAFFN8B-Affiliate_N8B	
Revisions:
	-- DB03.BODB02--> Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
*/
SET NOCOUNT ON
select FuncId, FuncName, FuncDesc, FileNames, (select count(funcid) from AffFunctionInfo acc1 with (nolock) where acc1.parentid = acc.funcid and acc1.parentid <> acc1.funcid) as SubFuncCount
from AffFunctionInfo acc with (nolock)
where FuncId = @FuncId

GO