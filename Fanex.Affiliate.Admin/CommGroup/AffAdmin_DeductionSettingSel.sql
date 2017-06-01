USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_DeductionSettingSel] 
	@GroupIDList	VARCHAR(1000)
	,@Date			SMALLDATETIME = NULL
AS

/*
	Created: 20130909@Joseph
	Task: Get all deduction settings
	DB: DBAFF
	Original:

	Revisions:
		- 20140820@Bobby: Apply SQL stylescope
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TblGroup TABLE (val NVARCHAR(6))

	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	INSERT INTO @TblGroup (val)
	SELECT val FROM [dbo].[strSplit](@GroupIDList, ',')

	IF (@Date IS NULL OR DATEDIFF(MONTH, CURRENT_TIMESTAMP, @Date) >= 0)
	BEGIN
		SELECT
			ds.DeductionID
			,ds.GroupID
			,ds.DeductedPercentage
			,d.ProductID
			,d.DTypeName
		FROM dbo.DeductionSetting ds WITH (NOLOCK)
			INNER JOIN dbo.DeductionType d WITH (NOLOCK) ON ds.DeductionID = d.DTypeId
		WHERE ds.GroupID IN (SELECT val FROM @TblGroup)
			AND d.isTest <= @isTest
	END
	ELSE
	BEGIN
		SELECT
			ds.DeductionID
			,ds.GroupID
			,ds.DeductedPercentage
			,d.ProductID
			,d.DTypeName
		FROM dbo.DeductionSettingHistory ds(NOLOCK)
			INNER JOIN dbo.DeductionType d WITH (NOLOCK) ON ds.DeductionID = d.DTypeId
		WHERE ds.GroupID IN (SELECT val FROM @TblGroup)
			AND DATEDIFF(m, ds.MonthDate, @Date) = 0
			AND d.isTest <= @isTest
	END
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DeductionSettingSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DeductionSettingSel] TO [vnteam]
GO