/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_FuncInfoSelByFuncID]
	@FuncId INT
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/
BEGIN
	SET NOCOUNT ON

	SELECT
		FuncId
	   ,FuncName
	   ,FuncDesc
	   ,FileNames
	   ,(SELECT
				COUNT(FuncId)
			FROM AffFunctionInfo acc1 WITH (NOLOCK)
			WHERE acc1.ParentId = acc.FuncId
			AND acc1.ParentId <> acc1.FuncId)
		AS SubFuncCount
	FROM AffFunctionInfo acc WITH (NOLOCK)
	WHERE FuncId = @FuncId
END
GO