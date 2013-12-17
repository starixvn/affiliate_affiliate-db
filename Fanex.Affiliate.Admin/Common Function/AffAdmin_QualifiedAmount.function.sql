CREATE FUNCTION [dbo].[AffAdmin_QualifiedAmount]
(
	@AffId int,
	@MonthDate datetime
)
RETURNS money
AS
BEGIN
	Declare @result money
	
	IF Exists (SELECT 1 From CommGroupHistory nolock where datediff(m, MonthDate, @MonthDate) = 0)
	Begin
		Select @result = (Select top 1 QualifiedAmount
						From CommGroupHistory c with (nolock)
							inner JOIN AffGroupHistory a with (nolock) on c.GroupId = a.GroupId
						where a.AffId = @AffId and DATEDIFF(m, a.MonthDate, @MonthDate) = 0
						)
	End
	Else
	Begin
		Select @result = (Select top 1 QualifiedAmount
						From CommGroup c with (nolock)
							inner JOIN AffInfo a with (nolock) on c.GroupId = a.GroupId
						where a.AffId = @AffId
						)
	End

	Return @result

END