/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_UpdAffType]
	@LicenseeID INT,
	@UserId int ,  
	@AffID int,  
	@AffType tinyint,    
	@IP nvarchar(15)='',   
	@Language varchar(5)= 'en-US',   
	@ErrCode int = 0 OUTPUT 
AS

/*
	Revisions:
		- 20151123@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
*/

BEGIN
	SET NOCOUNT ON  
   
	If(Not Exists (Select 1 from AffInfo (nolock) where AffID=@AffID ))  
	BEGIN  
		Select @ErrCode = 13  --'Error! This affiliate does not exist!'
		return
	END  

	update AffInfo with (rowlock,updlock)  
	Set AffType=@AffType  
	where AffID=@AffID  
  
	declare @SPName varchar(50), @Detail nvarchar(4000)   
	select @SPName = OBJECT_NAME(@@ProcID)  
	select @Detail = 'Update AffInfo AffType. AffID= ' + dbo.Aff_ToString(@AffID)   
		+'AffType= ' + dbo.Aff_ToString(@AffType)   
    
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @UserId,  
		@AffID = @AffID,  
		@Typename = 'AffInfo', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP  
END
GO