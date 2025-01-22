/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_LogType_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Customer - View Log - Log Type

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TypeId, TypeName FROM dbo.LogType WITH (NOLOCK)
END
GO