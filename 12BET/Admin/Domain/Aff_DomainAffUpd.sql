/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_DomainAffUpd]
	@DomainID int,
	@DomainName nvarchar(50), 	
	@UserID int,
	@IsSSL BIT = 0,
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
	Created: 20121115@ThaiTran
	Task: Update a AffDomain
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20180412@Percy: Add IsSSL [RedmineID: #92544]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid = @UserID,
		@funcname = '[Domain]',
		@System = 'AFFILIATE',
		@ErrCode = @ErrCode output,
		@ErrMsg = @ErrMsg output
	
	If @ErrCode <> 0
		RETURN

	--------------------------------------------
	SET @DomainName = RTRIM(LTRIM(@DomainName))
	SET @IsSSL = ISNULL(@IsSSL, 0)

	IF EXISTS (
				SELECT 1
				FROM [AffDomain] NOLOCK
				WHERE DomainID <> @DomainID
					AND DomainName = @DomainName
					AND IsDeleted = 0
				)
		BEGIN
			SELECT @ErrCode = 1001
				,@ErrMsg = 'This Affiliate domain has been existed!'

			RETURN
		END
	
	-----------------------------------------------
	BEGIN TRANSACTION

	UPDATE [AffDomain] with (rowlock,updlock)
	SET
		[ModifyDate] = getdate(),
		[DomainName] = @DomainName,              
		[Creator] = @UserID,
		[IsSSL] = ISNULL(@IsSSL, 0)
	WHERE DomainID = @DomainID

	IF @@Error <> 0 
	BEGIN
		ROLLBACK TRANSACTION
		Select @ErrMsg = N'Error occurs.Update unsuccessfully.', @Errcode=1001
		return
	END 	

	COMMIT TRANSACTION

	--Write log
	declare @SPName varchar(50), @Detail nvarchar(4000) 
	
	select @SPName = OBJECT_NAME(@@ProcID)
	
	select @Detail = 'Update DomainID:' + dbo.Aff_ToString(@DomainID)                     
						+ ' DomainName:' + dbo.Aff_ToString(@DomainName)         
						+ ' IsSSL:' + dbo.Aff_ToString(@IsSSL)           

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@Typename = 'AffDomain',
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO