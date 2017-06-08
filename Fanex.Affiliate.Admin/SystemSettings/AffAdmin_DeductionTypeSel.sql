USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DeductionTypeSel]
AS

/*
	Created: 20130909@Joseph
	Task: Get all deduction types (paging)
	DB: DBAFF.Affiliate_Athena000
	Original:

	Revisions:
		- 20140826@Bobby: add RemovedDate info
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	SELECT dt.DTypeID
		,dt.ProductID
		,dt.DTypeName
		,dt.DTypeDesc
		,dt.DeductedPercentage
		,dt.RemovedDate
	FROM dbo.DeductionType dt WITH(NOLOCK)
	WHERE dt.IsTest <= @isTest
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DeductionTypeSel] TO [bodbAdminNet]
GO