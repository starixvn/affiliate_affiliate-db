/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_FuncInfoSelByFuncID]
	@FuncId INT
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		-- DB03.BODB02--> Affiliate_12BET
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP for DBAFFYASHBET-Affiliate_YashBet [RedmineID: #198909]
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