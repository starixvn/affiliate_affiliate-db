/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LogType_Sel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Customer - View Log - Log Type

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TypeId, TypeName FROM dbo.LogType WITH (NOLOCK)
END
GO