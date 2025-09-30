Alter Procedure [Aff_WriteLog_UserLog_RunSP]
	@Creator INT,
	@AffID INT = 0,
	@SPName VARCHAR(50)=NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER
	@Details VARCHAR(4000) = NULL, --
	@IsAdmin bit = 0,	
	@IP varchar(25)=NULL
AS
/* Created:
	Task: Write Log function before run SP
	DB: DB052.Affiliate_12Bet

	Revisions:		    
	
	Param's Explaination:    	
	- @UserID: UserId perform this action
	- @CustID: CustId is called
	- @SPName Store name
	- @Doing: Action on store
	- @IsAdmin: 0(Affiliate), 1(Admin Affiliate)
	- @IP 
*/
SET NOCOUNT ON;   

INSERT INTO dbo.UserLog_RunSP(	
	[AffID]
	,[Creator]
	,[SPName]
	,[Details]
	,[LoggedDate]
	,[IsAdmin]
	,[IP])
VALUES (
	@AffID
	,@Creator 
	,@SPName
	,@Details
	,getdate()
	,@IsAdmin
	,@IP)

GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog_UserLog_RunSP] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog_UserLog_RunSP] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog_UserLog_RunSP] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_WriteLog_UserLog_RunSP] TO [VnTeam]