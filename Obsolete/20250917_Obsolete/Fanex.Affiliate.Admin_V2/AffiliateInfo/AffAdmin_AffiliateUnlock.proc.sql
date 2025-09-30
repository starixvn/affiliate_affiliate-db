/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateUnlock]  
	@LicenseeID INT,
	@UserId int,   
	@AffId int,      
	@Ip varchar(20),  
	@ErrCode int = 0 OUTPUT 
AS  

/*  
	Created: 20131112@JohnnyTrinh
	Task: Unlock affiliate
	DB: DBAFF
	Original:
  
	Revisions:  
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
	
	Parameters:  
		.@UserID: Administrator user id  
		.@GroupID: <1000  
		.@@AffID: AffID
		.@IP: IP of admin user
*/

BEGIN
	SET NOCOUNT ON
	 
	update AffInfo with (rowlock,updlock)  
	set IsLocked=0 
	where AffID = @AffID
  
	UPDATE AffDetail with (rowlock, updlock)  
	SET logincount = 0  
	WHERE AffID = @AffID  
  
	 --Write the log   
	DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
    
	SELECT @LogData = N'Unlock Affiliate.AffID=' + dbo.Aff_ToString(@AffID)
  
	select @SPName=OBJECT_NAME(@@ProcID)  

	EXEC [dbo].[Aff_WriteLog]  
			@Creator=@UserId,   
			@AffID=@AffID,  
			@Typename= 'Affiliate',   
			@SPName=@SPName,  
			@IP=@IP,  
			@Details=@LogData
END
GO