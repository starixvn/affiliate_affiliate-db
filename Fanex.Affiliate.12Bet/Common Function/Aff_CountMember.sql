USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_CountMember]    Script Date: 09/09/2009 16:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[Aff_CountMember] (
@AffID int)
RETURNS int
AS
/*
	Task : Count number of members for Affiliate
	Author : Peter@20090909
	
*/
BEGIN	
   Declare @count int
	
	select @count=Sum(1)
   from MemberInfo with (nolock)  
   where AffID=@AffID and IsRemoved = 0   
  return @count
END