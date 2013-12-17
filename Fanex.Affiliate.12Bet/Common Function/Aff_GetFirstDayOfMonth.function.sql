set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER function [dbo].[Aff_GetFirstDayOfMonth] (
@Date datetime)
RETURNS datetime
AS
BEGIN		
	RETURN CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@Date)-1),@Date),101)
END