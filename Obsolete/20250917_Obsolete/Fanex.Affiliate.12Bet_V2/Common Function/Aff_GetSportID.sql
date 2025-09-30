USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetSportID]    Script Date: 09/09/2009 16:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[Aff_GetSportID] (
@SportName varchar(2048))
RETURNS smallint
AS
/*
	Task : Get Sport ID
	Author : Peter@20090909
	
*/
BEGIN	
	DECLARE @SportID smallint	
	SELECT @SportID=SportID from SportType with (nolock)
	where SportName=@SportName
	RETURN @SportID
END