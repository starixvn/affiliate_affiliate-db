  USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetCurrencyGroup]    Script Date: 09/09/2009 16:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[Aff_GetCurrencyGroup] (
@AffID int,@SportID tinyint, @Currency int,@MonthDate smalldatetime)
RETURNS int
AS
/*
	Task : Get Gurrency Group ID of this currency
	Author : Peter@20110621
	@MonthDate=null : current month
*/
BEGIN	 
		
	select @MonthDate=isnull(@MonthDate,current_timestamp) 
	declare @GroupID int,@CurrencyCode nvarchar(50)
	Select  @CurrencyCode=Currency
	from Exchange_Current (nolock)
	where exchangeid= @Currency  
	if(datediff(m,current_timestamp,@MonthDate)<0)
	BEGIN
		Select @GroupID=cg.GroupID
			from CurrencyGroupHistory cg (nolock)
			where cg.CurrencyList like '%' + @CurrencyCode + '%'
				and cg.MonthDate=@MonthDate
				and cg.GroupID in
				(	
					select gs.CurrencyGroup
					from AffGroupHistory ah (nolock)
					inner join GroupSettingHistory gs (nolock) on gs.GroupID=ah.GroupID	
					where ah.AffID=@AffID and gs.SportType=@SportID
						and ah.MonthDate=@MonthDate and gs.MonthDate=@MonthDate
				 )		
	END
	ELSE
	BEGIN		
	
		Select @GroupID=cg.GroupID
		from CurrencyGroup cg (nolock)
		where cg.CurrencyList like '%' + @CurrencyCode + '%'
			and cg.GroupID in
			(	
				select gs.CurrencyGroup
				from AffInfo ai (nolock)
				inner join GroupSetting gs (nolock) on gs.GroupID=ai.GroupID	
				where ai.AffID=@AffID and gs.SportType=@SportID
			)		
			  
	END
		 
	return isnull(@GroupID,0)
END