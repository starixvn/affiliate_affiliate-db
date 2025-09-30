/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateUpdClosedStatus]  
	@LicenseeID INT,
	@affid int,  
	@userid int,  
	@closed bit,  
	@ip varchar(20),  
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT 
AS

/*
	Created by: 20090321@Peter  
	Task:
	DB: DBAFF
	Original: [Aff_AffiliateUpdClosedStatus]  

	Revisions:  
		- 20151123@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:  
		• @affid: Affiliate id  
		• @userid: User update  
		• @closed: Status of affiliate.  
		• @ip: Ip of Admin user  
*/

BEGIN
	SET NOCOUNT ON  
	
	Declare @LoginCount int, @Old_Closed bit, @RefNo bigint  
	
	select @LoginCount = LoginCount    
	from AffDetail with (nolock)    
	where AffID = @affid    
    
	select @Old_Closed=IsClosed  
	from AffInfo with (nolock)    
	where AffID = @AffID   
  
	--This account is closed because last try to login failed more than 5 times    
	--So no need top update this just temporarily lock  
	IF @Old_Closed = @Closed and @LoginCount > 5    
	  return    
  
	Update AffInfo with(rowlock,updlock) set [IsClosed]=@closed where affid=@affid  
	
	IF @@error<>0   
	Begin  
		SELECT @ErrCode = 1005  
		RETURN  
	END  
	
	Declare @NoCommGroupId int, @AffList nvarchar(200)  

	if @Closed = 1  
	BEGIN  
		select @NoCommGroupId = GroupId from CommGroup with (nolock) where GroupName = 'NoCommission'  
   
		select @AffList = cast(@affid as nvarchar(20))  
  
		Exec Aff_CommGroupAssign  
			@UserId = @userid,  
			@GroupId = @NoCommGroupId,  
			@AffIDList = @AffList,      
			@IP = @ip,  
			@ErrCode = @ErrCode OUTPUT,  
			@RefNo = @RefNo OUTPUT  
    
		IF @@error<>0   
			RETURN  
	END  
  
	--admin allow to loginable again  
	IF @Old_Closed = 1 and @Closed = 0 and @LoginCount > 5    
	BEGIN  
		update AffDetail with (ROWLOCK, UPDLOCK) set LoginCount = 0    
		where affid = @affid  
		
		IF @@error<>0   
		BEGIN  
			SELECT @ErrCode = 1005
			RETURN  
		END  
	END  
   
	--Write the log   
	DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
	SELECT @LogData = 'Update Affiliate''s Closed Status. '  
					  + 'IsClosed=' + dbo.Aff_ToString(@Closed)  
  
	select @SPName=OBJECT_NAME(@@ProcID)  
	
	EXEC [dbo].[Aff_WriteLog]  
		@Creator=@UserId,   
		@AffID=@AffID,  
		@Typename= 'UserInfo',   
		@SPName=@SPName ,  
		@IP =@IP,  
		@RefNo = @RefNo,  
		@Details=@LogData
END
GO