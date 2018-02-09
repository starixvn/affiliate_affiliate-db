/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_NoteUpd]
	@Noteid int ,
	@Content nvarchar(1000) ,
	@Updatedby int ,
	@AdminUserName VARCHAR(50),
	@AffId int,
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT
AS

/*
	Created by: 20090122@TrangLe
	Task:
	DB: DBAFF
	Original:

	Revisions:
		- 20100904@Johnny: Check permission (media affiliate, normal affiliate on this function)
		- 20151123@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]

	Param's Explanation:
		. @Noteid: autonumber output
		. @Content: content of the note
		. @AffId Affiliate ID
		. @Updatedby: User cust id
*/

BEGIN
	SET NOCOUNT ON

	BEGIN TRANSACTION

	UPDATE dbo.AdminNotes WITH(ROWLOCK, UPDLOCK)
	SET 	
		Updateddate = GETDATE(),
		Note = @Content,
		Updatedby = @Updatedby,
		UpdatedByName = @AdminUserName
	WHERE Noteid = @Noteid

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 51
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update Note ID:' + dbo.Aff_ToString(@Noteid)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @AffId,
		@Typename = 'UserNote', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO