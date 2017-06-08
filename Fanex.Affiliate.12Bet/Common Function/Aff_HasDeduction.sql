USE [Affiliate_12BET]
GO

ALTER function [dbo].[Aff_HasDeduction] (
@GroupID int,@SportID tinyint, @DeductionName nvarchar(50),@MonthDate smalldatetime)
RETURNS bit
AS
/*
	Task : Check a sport has a deduction name
	Author : Peter@20090909
	@MonthDate=null : current month

	Revisions:
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]
*/
BEGIN	 
	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	select @MonthDate=isnull(@MonthDate,current_timestamp) 
	if(datediff(m,current_timestamp,@MonthDate)<0)
	BEGIN
	   if(exists (select top(1) 1 
				  from DeductionSettingHistory with (nolock) 
				  where GroupID=@GroupID 
						and datediff(m,MonthDate,@MonthDate)=0 
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where SportID=@SportID and DTypeName=@DeductionName and IsTest <= @isTest) 
				   )
			)
		  return 1
	   else
		 return 0
	END
	ELSE
	BEGIN
	   if(exists (select top(1) 1 
				  from DeductionSetting with (nolock) 
				  where GroupID=@GroupID 						
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where SportID=@SportID and DTypeName=@DeductionName and IsTest <= @isTest) 
				   )
			)
		  return 1
	   else
		 return 0
	END
		 
   return 0 
END