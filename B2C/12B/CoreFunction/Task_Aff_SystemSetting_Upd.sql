/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_SystemSetting_Upd]
	@SName		VARCHAR(50)
	,@SValue	VARCHAR(200)
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function update data in SystemSettings

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	BEGIN TRY
		UPDATE dbo.SystemSettings WITH (ROWLOCK)
		SET SValue = @SValue
		WHERE SName = @SName
	END TRY
	BEGIN CATCH
		-- PRINT 'Error!'
	END CATCH
END
GO