 USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_ToString]    Script Date: 09/09/2009 16:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[Aff_ToString] (
 @Value sql_variant
)
RETURNS nvarchar(4000)
AS
/*
	DB : DB02.bodb02, DB03.on_user,DB03.bodb02,DB052.Affiliate_12BET
	Task : Convert a value to string for all data types
	Author : Peter@20090909
	
*/
BEGIN	   
	return cast(isnull(@Value,'') as nvarchar(4000))
END