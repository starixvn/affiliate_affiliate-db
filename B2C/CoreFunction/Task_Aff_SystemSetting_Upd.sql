/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_SystemSetting_Upd]
	@SName		VARCHAR(50)
	,@SValue	VARCHAR(200)
AS

/*
	Created: 20210317@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core function update data in SystemSettings

	Revisions:
		- 20210317@Percy: Initialize SP [RedmineID: #151391]
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