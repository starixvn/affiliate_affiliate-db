/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateUpdPwd]
	@Id int,
	@OldPassword nvarchar(50)=null,
	@Password nvarchar(50),
	@UserId int = null,
	@IP varchar(20),	
	@ErrCode int = 0 OUTPUT
AS

/*
	Created: 200908230@DungTong
	Task: Admin Reset Password for Affiliate or Affiliate change password
	DB: DBAFF

	Revisions:
	  - 20090930@VinhTrinh: Admin Change Affiliate Password
	  - 20130827@Joseph: rename and update params
	  - 20151127@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	  - 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
	• 
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

	if not exists(select 1 from AffInfo with (NOLOCK) 
					where AffID = @Id
					and (case when (@OldPassword is not null and Password = @OldPassword) or @OldPassword is null then 1 
							else 0 end ) = 1 )
	BEGIN
		Select @ErrCode = 11
		RETURN 
	END


	UPDATE AffInfo  with (ROWLOCK, UPDLOCK)
	SET Password=@Password
	where AffID=@Id

	declare @SPName varchar(50), @LogData nvarchar(200)
	Select @LogData = 'Reset password'
	select @SPName = OBJECT_NAME(@@ProcID)
	select @UserID = isnull(@UserID, @Id)

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserID,
		@AffID = @Id,
		@Typename = 'Password', -- refer to table LogType
		@SPName = @SPName,
		@Details = @LogData,
		@IP = @IP
END
GO