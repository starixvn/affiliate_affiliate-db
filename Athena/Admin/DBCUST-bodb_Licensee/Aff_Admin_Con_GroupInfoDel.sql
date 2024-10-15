/*<info serverAlias="DBCUST-bodb_Licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
USE [bodb_Licensee]
GO
CREATE PROCEDURE [dbo].[Aff_Admin_Con_GroupInfoDel]
	@LicenseeID	INT,
	@GroupID	INT,
	@ErrCode	INT = 0 OUTPUT
AS

/*
	Create: 20240802@Sally
	DB: DBCUST-bodb_Licensee
	Task: Remove linked server to DBCust
	Orig: DBAFF-Affiliate_Athena000/AffAdmin_Con_GroupInfoDel

	Revisions:
		- 20240802@Sally: Initialize SP [RedmineID: #206891] 

*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @IsHasMember BIT = 0

	SELECT @IsHasMember = 1 
	FROM dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) f
	WHERE f.GroupID = @GroupID

	IF (@IsHasMember = 1) 
	BEGIN
		SELECT @ErrCode = 14
		RETURN
	END
	
	EXEC dbo.AffAdmin_GroupPolicy_Delete @GroupID = @GroupID
	EXEC dbo.AffAdmin_GroupInfo_Delete @GroupID = @GroupID

END
GO