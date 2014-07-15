ALTER FUNCTION [dbo].[AffAdmin_QualifiedAmount] (
	@AffId INT
	,@MonthDate DATETIME
	)
RETURNS MONEY
AS
/*Created: 20090828@Peter    
Task : Get Qualified Amount of aff user and commgroup
Original DB: DBAFF.Affiliate_Athena000
    
Revisions:    
 - 20140703@bobby: Add constraint MonthDate beween AffGroupHistory and CommGroupHistory

Param's Explanation:    
    
*/
BEGIN
	DECLARE @result MONEY

	IF EXISTS (
			SELECT 1
			FROM CommGroupHistory NOLOCK
			WHERE datediff(m, MonthDate, @MonthDate) = 0
			)
	BEGIN
		SELECT @result = (
				SELECT TOP 1 QualifiedAmount
				FROM AffGroupHistory a WITH (NOLOCK)
					INNER JOIN CommGroupHistory c WITH (NOLOCK) 
					ON a.GroupId = c.GroupId
						AND a.MonthDate = c.MonthDate
				WHERE a.AffId = @AffId
					AND DATEDIFF(m, a.MonthDate, @MonthDate) = 0
				)
	END
	ELSE
	BEGIN
		SELECT @result = (
				SELECT TOP 1 QualifiedAmount
				FROM CommGroup c WITH (NOLOCK)
					INNER JOIN AffInfo a WITH (NOLOCK) ON c.GroupId = a.GroupId
				WHERE a.AffId = @AffId
				)
	END

	RETURN @result
END
