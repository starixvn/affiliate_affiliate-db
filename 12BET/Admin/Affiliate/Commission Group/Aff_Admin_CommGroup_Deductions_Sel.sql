/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Deductions_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Add new commission group - Select deductions

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	SELECT DeductionId, DeductionName, DeductedPercentage
	FROM dbo.Deductions WITH (NOLOCK)
	WHERE
		IsTest <= @isTest
		AND IsDeleted = 0
END
GO