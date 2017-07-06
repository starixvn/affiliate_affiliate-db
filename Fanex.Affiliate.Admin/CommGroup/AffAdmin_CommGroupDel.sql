/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CommGroupDel]  
	@LicenseeID INT,
	@UserId int,  
	@GroupId int,  
	@IP varchar(20),  
	@ErrCode int = 0 OUTPUT 
AS

/*
	Created: 20090719@DungTong  
	Task: Delete a Commission Group   
	DB: DBAFF
	Original:
  
	Revisions: 
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site 
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON  
	
	if (not exists (select 1 from CommGroup(nolock) where GroupID = @GroupID and IsDeleted=0))  
	begin  
		select @ErrCode=31
		return  
	end 

	--Check this group has 0 of affilliate assigment   
	declare @noOfAff int  
	select @noOfAff= COUNT(1) from AffInfo i with (nolock) where i.GroupID=@GroupID  
  
	if(@noOfAff>0)    
	begin  
		select @ErrCode=32
		return  
	end  
  
	update CommGroup with (rowlock, updlock)  
	set isDeleted = 1  
	where GroupId = @GroupId  
	
	--Write the log   
	DECLARE @LogData nvarchar(200), @AffID int,@SPName varchar(100)  
	
	if (@GroupID>1000)  
		select @AffID=@GroupID  
	else  
		select @AffID=0    
	
	SELECT @LogData = 'Delete commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
  
	select @SPName=OBJECT_NAME(@@ProcID)  
	
	EXEC [dbo].[Aff_WriteLog]  
		@Creator=@UserId,   
		@AffID=@AffID,
		@Typename= 'CommissionGroup',   
		@SPName=@SPName ,  
		@IP =@IP,  
		@Details=@LogData
END
GO