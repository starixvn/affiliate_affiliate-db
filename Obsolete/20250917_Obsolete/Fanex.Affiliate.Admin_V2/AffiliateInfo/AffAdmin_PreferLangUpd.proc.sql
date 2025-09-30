/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_PreferLangUpd]  
	@LicenseeID INT,
	@affid int,  
	@userid int,  
	@PreferredLanguage varchar(5),    
	@IP varchar(20),  
	@Language varchar(5) = 'en-US',    
	@ErrCode int = 0 OUTPUT
AS  
  
/*
	Created by: 20090822@Peter  
	Task:
	DB: DBAFF
	Original: [Aff_PreferLangUpd]  
	
	Revisions:
		- 20151123@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
  
	Param's Explanation:  
		• @custid : Affiliate custid  
		• @userid : User update  
		• @PreferredLanguage : Preferred language update.  
*/ 

BEGIN
	SET NOCOUNT ON  

	if(not exists(select 1 from AffInfo(nolock) where affid=@affid))  
	begin  
			 SELECT @ErrCode = 1006  
	   return  
	end  
   
	Update AffDetail with(rowlock,updlock)  
	set PreferredLanguage = @PreferredLanguage  
	where affid = @affid  
  
	IF @@error<>0   
	Begin  
		SELECT @ErrCode = 1005  
		RETURN  
	END  
  
	--Write the log   
	DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
	SELECT @LogData = 'Update Affiliate''s Prefered Languague. '  
					  + 'PreferredLanguage=' +  dbo.Aff_ToString(@PreferredLanguage)  
  
	select @SPName=OBJECT_NAME(@@ProcID)  
   
	EXEC [dbo].[Aff_WriteLog]  
		@Creator=@UserId,   
		@AffID=@AffID,  
		@Typename= 'UserInfo',   
		@SPName=@SPName ,  
		@IP =@IP,  
		@Details=@LogData
END
GO