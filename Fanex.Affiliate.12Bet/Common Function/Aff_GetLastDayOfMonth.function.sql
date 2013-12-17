set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER function [dbo].[Aff_GetLastDayOfMonth] (
@Date datetime)
RETURNS datetime
AS

BEGIN		
	RETURN DATEADD(ms,-1,DATEADD(mm, DATEDIFF(m,0,@Date)+1,0))
END

