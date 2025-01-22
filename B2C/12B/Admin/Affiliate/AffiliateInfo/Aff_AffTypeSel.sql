/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_AffTypeSel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Get list afftype

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON;

	SELECT TypeId
		,NAME
		,NAME AS TypeName -- backup to old version
		,[Description]
	FROM dbo.AffType WITH (NOLOCK)
	WHERE IsShown = 1
END
GO