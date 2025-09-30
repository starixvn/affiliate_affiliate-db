/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_NoteDel]
	@LicenseeID INT,
	@AffId int,
	@listnode varchar(500),
	@UserID int,
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
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
		. @Noteid: Note needs to be deleted.
		. @UserID: User to be logged
*/

BEGIN
	SET NOCOUNT ON

	BEGIN TRANSACTION

	DELETE dbo.AdminNotes WITH(ROWLOCK, UPDLOCK)
	WHERE Noteid IN (SELECT val FROM strSplit(@listnode, ';'))

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 52
		RETURN
	END

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Delete Notes:' + dbo.Aff_ToString(@listnode)

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @UserID,
		@AffID = @AffID,
		@Typename = 'UserNote', -- refer to table LogType
		@SPName = @SPName,
		@IP = @IP,
		@Details = @Detail
END
GO