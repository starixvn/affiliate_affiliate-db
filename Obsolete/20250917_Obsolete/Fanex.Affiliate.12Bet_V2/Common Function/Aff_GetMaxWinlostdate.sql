   USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetMaxWinlostdate]    Script Date: 09/09/2009 16:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[Aff_GetMaxWinlostdate] (
@AffID int,@SportID tinyint,@MonthDate smalldatetime)
RETURNS smalldatetime
AS
/*
	Task : Get the current max winlostdate for a specific month of affiliate
	Author : Peter@20101126
	@MonthDate=null : current month
*/
BEGIN	 
	
   select @MonthDate=isnull(@MonthDate,current_timestamp) 
   
   declare @MaxWinlostDate smalldatetime
   select @MaxWinlostDate=max(winlostdate)
   from AffDailySummary (nolock) 
		where datediff(m,winlostdate,@MonthDate)=0
			 and AffID=	@AffID and SportId=@SportID
			 
   return @MaxWinlostDate
END