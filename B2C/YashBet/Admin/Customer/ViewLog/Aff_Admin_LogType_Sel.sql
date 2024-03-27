/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LogType_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Customer - View Log - Log Type

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TypeId, TypeName FROM dbo.LogType WITH (NOLOCK)
END
GO