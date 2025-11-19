/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_MemberInfo_ImportedTime]
	@LastImportedTime 	DATETIME
	,@SName 			VARCHAR(50) = 'MemberInfoLastImportedTime'
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20250114@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Job (web call) - After import member info

	Revisions:
		- 20250114@Eddie: Initialize SP [RedmineID: #212201]
	Note:
		@SName = 'MemberInfoLastImportedTime'
*/

BEGIN

	IF @LastImportedTime IS NOT NULL
	BEGIN
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = CONVERT(VARCHAR(20), @LastImportedTime, 120)
		WHERE SName = @SName
	END
	ELSE
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid update!!!'
	END
END
GO