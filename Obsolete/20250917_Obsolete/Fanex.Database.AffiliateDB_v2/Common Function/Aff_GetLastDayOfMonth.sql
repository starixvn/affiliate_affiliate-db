ALTER function [dbo].[Aff_GetLastDayOfMonth] (
@Date datetime)
RETURNS datetime
AS

BEGIN		
	RETURN DATEADD(s,-60, DATEADD(mm, DATEDIFF(m,0,@Date)+1,0))
END
