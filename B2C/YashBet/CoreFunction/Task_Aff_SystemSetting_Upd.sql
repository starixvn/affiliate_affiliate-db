/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_SystemSetting_Upd]
	@SName		VARCHAR(50)
	,@SValue	VARCHAR(200)
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function update data in SystemSettings

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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