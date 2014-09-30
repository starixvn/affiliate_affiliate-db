ALTER FUNCTION [dbo].[AffAdmin_f_GetDeductionPercent] (
	@AffID 			INT
	,@ProductID 	TINYINT
	,@DeductionName NVARCHAR(50)
	,@MonthDate 	SMALLDATETIME
	)
RETURNS FLOAT
AS
/*
    Task : Check a sport has a deduction name
    Author : Bobby@20140822
	Orgiginal:Aff_GetDeductionPercent
    @MonthDate=null : current month
*/
BEGIN
	DECLARE @percent FLOAT

	SELECT @MonthDate = ISNULL(@MonthDate, CURRENT_TIMESTAMP)
		,@percent = 0

	IF (DATEDIFF(m, CURRENT_TIMESTAMP, @MonthDate) < 0)
	BEGIN
		SELECT @percent = ISNULL(dh.DeductedPercentage, 0)
		FROM dbo.AffGroupHistory ag WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dh WITH (NOLOCK)
			ON ag.GroupID = dh.GroupID
				AND ag.MonthDate = dh.MonthDate
			INNER JOIN dbo.DeductionType dt WITH(NOLOCK)
			ON dh.DeductionID = dt.DTypeID
		WHERE ag.AffID = @AffID
			AND DATEDIFF(m, ag.MonthDate, @MonthDate) = 0
			AND dt.DTypeName = @DeductionName
			AND dt.ProductID = @ProductID
	END
	ELSE
	BEGIN

		SELECT @percent = ISNULL(ds.DeductedPercentage, 0)
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN dbo.DeductionSetting ds WITH (NOLOCK)
			ON ai.GroupID = ds.GroupID
			INNER JOIN dbo.DeductionType dt WITH(NOLOCK)
			ON ds.DeductionID = dt.DTypeID
		WHERE ai.AffID = @AffID
			AND dt.ProductID = @ProductID
			AND dt.DTypeName = @DeductionName
	END

	RETURN @percent
END