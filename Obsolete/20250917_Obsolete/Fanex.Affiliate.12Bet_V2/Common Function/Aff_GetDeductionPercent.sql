USE [Affiliate_12BET]
GO

ALTER function [dbo].[Aff_GetDeductionPercent] (
@AffID int,@SportID tinyint, @DeductionName nvarchar(50),@MonthDate smalldatetime)
RETURNS float
AS
/*
	Task : Check a sport has a deduction name
	Author : Peter@20090909
	@MonthDate=null : current month

	Revisions:
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]
*/
BEGIN	 
	declare @percent float,@GroupID int
	select @percent=null

	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)
	
   select @MonthDate=isnull(@MonthDate,current_timestamp) 
   if(datediff(m,current_timestamp,@MonthDate)<0)
	BEGIN
	   select @GroupID=GroupID
	   from AffGroupHistory with (nolock)
	   where AffID=@AffID and datediff(m,MonthDate,@MonthDate)=0
	   
	   select @percent= DeductedPercentage
	   from DeductionSettingHistory with (nolock) 
				  where GroupID=@GroupID 
						and datediff(m,MonthDate,@MonthDate)=0
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where SportID=@SportID and DTypeName=@DeductionName and IsTest <= @isTest)
	END
	ELSE
	BEGIN
	   select @GroupID=GroupID
	   from AffInfo with (nolock)
	   where AffID=@AffID
	   
	   select @percent= DeductedPercentage
	   from DeductionSetting with (nolock) 
				  where GroupID=@GroupID 						
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where SportID=@SportID and DTypeName=@DeductionName and IsTest <= @isTest)       
	END	
   return coalesce(@percent,0)
END