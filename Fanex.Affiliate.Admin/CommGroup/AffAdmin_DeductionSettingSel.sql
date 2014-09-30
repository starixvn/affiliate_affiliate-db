ALTER PROCEDURE [dbo].[AffAdmin_DeductionSettingSel] 
	@GroupIDList	VARCHAR(1000)
	,@Date			SMALLDATETIME = NULL
AS
/*
Created: 20130909@Joseph
Task : Get all deduction settings
DB: DB052.
Original:

Revisions:
	- 20140820@Bobby: Apply SQL stylescope
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @TblGroup TABLE (
		id INT PRIMARY KEY
		,rank INT
		,val NVARCHAR(6)
		)

	INSERT INTO @TblGroup
	SELECT *
	FROM [dbo].[strSplit](@GroupIDList, ',')

	IF (@Date IS NULL
		OR DateDiff(m, CURRENT_TIMESTAMP, @Date) >= 0)
	BEGIN
		SELECT ds.DeductionID
			,ds.GroupID
			,ds.DeductedPercentage
			,d.ProductID
			,d.DTypeName
		FROM dbo.DeductionSetting ds WITH (NOLOCK)
			INNER JOIN dbo.DeductionType d WITH (NOLOCK) 
			ON ds.DeductionID = d.DTypeId
		WHERE ds.GroupID IN (
				SELECT val
				FROM @TblGroup
				)
	END
	ELSE
	BEGIN
		SELECT ds.DeductionID
			,ds.GroupID
			,ds.DeductedPercentage
			,d.ProductID
			,d.DTypeName
		FROM dbo.DeductionSettingHistory ds(NOLOCK)
			INNER JOIN dbo.DeductionType d WITH (NOLOCK) 
			ON ds.DeductionID = d.DTypeId
		WHERE ds.GroupID IN (
				SELECT val
				FROM @TblGroup
				)
			AND DATEDIFF(m, ds.MonthDate, @Date) = 0
	END
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_DeductionSettingSel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DeductionSettingSel] TO [vnteam]
