ALTER FUNCTION [dbo].[Aff_GetQMTurnOver] (
	@AffID INT
	,@MonthDate DATETIME = NULL
	)
RETURNS MONEY
AS
/*
    Task : Get Balance Brought Forward for Affiliate
    Author : Peter@20090909
    
	Revision:
		-20140804@Bobby: Update checking current month
*/
BEGIN
	SELECT @MonthDate = coalesce(@MonthDate, current_timestamp)

	SELECT @MonthDate = [dbo].[Aff_GetLastDayOfMonth](@MonthDate)

	SELECT @MonthDate = dbo.Aff_GetSmallDatetime(@MonthDate)

	DECLARE @QMTurnover MONEY

	IF (datediff(m, @MonthDate, current_timestamp) = 0)
	BEGIN
		SELECT @QMTurnover = QualifiedAmount
		FROM AffInfo a WITH (NOLOCK)
			INNER JOIN CommGroup c WITH (NOLOCK) ON a.GroupId = c.GroupId
		WHERE AffId = @AffId
	END
	ELSE
	BEGIN
		SELECT @QMTurnover = QualifiedAmount
		FROM AffGroupHistory a WITH (NOLOCK)
			INNER JOIN CommGroupHistory c WITH (NOLOCK) ON a.GroupId = c.GroupId
			AND a.MonthDate = c.MonthDate
		WHERE a.AffId = @AffId
			AND a.MonthDate = @MonthDate
			AND c.MonthDate = @MonthDate
	END

	RETURN isnull(@QMTurnover, 0)
END