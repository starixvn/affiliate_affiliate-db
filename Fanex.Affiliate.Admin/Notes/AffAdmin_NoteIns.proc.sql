/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_NoteIns]  
	@LicenseeID INT,
	@Content NVARCHAR(1000),  
	@AffId INT,  
	@Updatedby INT,  
	@IP NVARCHAR(15) = '',  
	@Language VARCHAR(5) = 'en-US', 
	@ErrCode INT = 0 OUTPUT
AS

/*
	Created by: 20090122@TrangLe  
	Task:
	DB: DBAFF
	Original:  

	Revisions:  
		- 20151123@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
		. @Noteid: autonumber output
		. @Note: content of the note
		. @AffId: Affiliate ID
		. @Updatedby: User cust id
*/

BEGIN
	SET NOCOUNT ON  

	DECLARE @Noteid INT

	BEGIN TRANSACTION
	 
	INSERT INTO AdminNotes  
	(
		[Note],
		[Updateddate],
		[AffID],
		[Updatedby]
	)
	VALUES
	(
		@Content,
		GETDATE(),
		@AffId,
		@Updatedby
	)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		
		SELECT @ErrCode = 50
		RETURN
	END

	SELECT @Noteid = SCOPE_IDENTITY()

	COMMIT TRANSACTION
  
	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'ALTER Note ID:' + dbo.Aff_ToString(@Noteid)
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @Updatedby,  
		@AffID = @AffId,  
		@Typename = 'UserNote', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP
END
GO