/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Deductions_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Add new commission group - Select deductions

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
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