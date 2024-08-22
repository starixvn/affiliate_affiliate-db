/*<info serverAlias="DBCUST-bodb_Licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Con_GroupInfoUpd]
	@GroupID	INT,
	@LicenseeID INT,
	@GroupName	NVARCHAR(50) = NULL,
	@GroupDesc	NVARCHAR(50) = NULL,
	@UserID		INT,
	@ErrCode	INT = 0 OUTPUT

AS

/*
	Created: 20240802@Sally
	DB: DBCUST-bodb_Licensee
	Task: Remove linked server to DBCust
	Orig: DBAFF-Affiliate_Athena000/dbo.AffAdmin_Con_GroupPolicySel

	Revisions:
		- 20240802@Sally: Initialize SP [RedmineID: #206891] 

*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX)
	DECLARE @IsExistedGroupName BIT = 0

	SELECT @IsExistedGroupName = 1 
	FROM dbo.AffAdmin_f_GroupInfo_Select('', @LicenseeID) f
	WHERE f.GroupName = @GroupName 
		AND f.GroupID <> @GroupID

	IF (@IsExistedGroupName = 1) 
	BEGIN
		SELECT @ErrCode = 21
		RETURN
	END
		
	EXEC dbo.AffAdmin_GroupInfo_Update @GroupID = @GroupID, @GroupName = @GroupName, @GroupDesc = @GroupDesc, @Creator = @UserID
		
END
GO
