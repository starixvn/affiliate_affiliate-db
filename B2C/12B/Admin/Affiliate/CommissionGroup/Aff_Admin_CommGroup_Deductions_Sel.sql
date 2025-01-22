/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_CommGroup_Deductions_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Add new commission group - Select deductions

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	SELECT DeductionId, DeductionName, DeductedPercentage, DeductedAmount, IsDeductedPercent, Commission
	FROM dbo.Deductions WITH (NOLOCK)
	WHERE IsTest <= @isTest
		AND IsDeleted = 0
END
GO