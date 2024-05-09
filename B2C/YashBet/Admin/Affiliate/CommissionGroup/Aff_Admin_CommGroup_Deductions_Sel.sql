/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Deductions_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Add new commission group - Select deductions

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
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