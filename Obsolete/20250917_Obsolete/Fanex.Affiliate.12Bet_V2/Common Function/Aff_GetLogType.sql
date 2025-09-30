 USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetLogType]    Script Date: 09/09/2009 16:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[Aff_GetLogType] (
@LogName varchar(2048))
RETURNS int
AS
/*
	Task : Get Log Type
	Author : Peter@20090909
	
*/
BEGIN	
	DECLARE @LogType int	
	SELECT @LogType=TypeID from LogType (nolock)
	where TypeName=@LogName
	RETURN @LogType
END