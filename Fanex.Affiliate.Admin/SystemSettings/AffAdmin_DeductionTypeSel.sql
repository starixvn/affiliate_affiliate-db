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
*/

BEGIN
	SET NOCOUNT ON

	SELECT dt.DTypeID
		,dt.ProductID
		,dt.DTypeName
		,dt.DTypeDesc
		,dt.DeductedPercentage
		,dt.RemovedDate
	FROM dbo.DeductionType dt WITH(NOLOCK)
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DeductionTypeSel] TO [bodbAdminNet]
GO