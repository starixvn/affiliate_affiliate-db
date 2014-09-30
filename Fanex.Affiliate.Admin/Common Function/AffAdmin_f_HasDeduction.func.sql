ALTER FUNCTION [dbo].[AffAdmin_f_HasDeduction] (
	@GroupID			INT
	,@ProductID			TINYINT
	,@DeductionName		NVARCHAR(50)
	,@MonthDate			SMALLDATETIME
	)
RETURNS BIT
AS
/*
	Task : Check a sport has a deduction name
	Author : Bobby@20140822
	Orgiginal:Aff_HasDeduction
	@MonthDate=null : current month
*/
BEGIN
	SELECT @MonthDate = ISNULL(@MonthDate, CURRENT_TIMESTAMP)

	IF (DATEDIFF(M, CURRENT_TIMESTAMP, @MonthDate) < 0)
	BEGIN
		IF (EXISTS (
					SELECT TOP (1) 1
					FROM dbo.DeductionSettingHistory ds WITH (NOLOCK)
						INNER JOIN dbo.DeductionType dt WITH (NOLOCK)
						ON ds.DeductionID = dt.DTypeID
					WHERE GroupID = @GroupID
						AND DATEDIFF(m, MonthDate, @MonthDate) = 0
						AND dt.ProductID = @ProductID
						AND dt.DTypeName = @DeductionName
					)
				) 
			BEGIN 
				RETURN 1
			END
	END
	ELSE
	BEGIN
		IF (EXISTS (
					SELECT TOP (1) 1
					FROM dbo.DeductionSetting ds WITH (NOLOCK)
						INNER JOIN dbo.DeductionType dt WITH (NOLOCK)
						ON ds.DeductionID = dt.DTypeID
					WHERE ds.GroupID = @GroupID
						AND dt.ProductID = @ProductID
						AND dt.DTypeName = @DeductionName
					)
			)
			BEGIN 
				RETURN 1
			END
	END

	RETURN 0
END