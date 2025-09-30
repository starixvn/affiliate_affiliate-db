ALTER FUNCTION [dbo].[Aff_IsProductInGroupOfAff] (
	@AffID INT
	,@ProductID INT
	,@MonthDate DATETIME = NULL
	)
RETURNS INT
AS
/*
Created: Peter
Date: 2009-12-10 
Task : Check Aff - group - product
DB: DBAFF/Athena000
Original: 

Revisions:
	- 20150413@Bobby: Update comparision with current month

Param's Explanation: 

*/
BEGIN
	IF @MonthDate > CURRENT_TIMESTAMP RETURN 0

	SELECT @MonthDate = coalesce(@MonthDate, current_timestamp)

	SELECT @MonthDate = [dbo].[Aff_GetLastDayOfMonth](@MonthDate)

	SELECT @MonthDate = dbo.Aff_GetSmallDatetime(@MonthDate)

	DECLARE @Result INT
		,@MonthDateCheck DATE = CONVERT(DATE, @MonthDate)

	IF (datediff(m, @MonthDate, current_timestamp) = 0)
	BEGIN
		SELECT @Result = count(DISTINCT c.ProductID)
		FROM AffInfo a WITH (NOLOCK)
			INNER JOIN GroupSetting c WITH (NOLOCK)
			ON a.GroupId = c.GroupId
		WHERE AffId = @AffId
			AND c.ProductID = @ProductID
	END
	ELSE
	BEGIN
		SELECT @Result = count(DISTINCT c.ProductID)
		FROM AffGroupHistory a WITH (NOLOCK)
			INNER JOIN GroupSettingHistory c WITH (NOLOCK)
			ON a.GroupId = c.GroupId
				AND a.MonthDate = c.MonthDate
		WHERE a.AffId = @AffId
			AND a.MonthDate = @MonthDate
			AND c.ProductID = @ProductID
	END

	RETURN isnull(@Result, 0)
END
