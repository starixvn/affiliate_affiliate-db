/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffTypeSel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Get list afftype

	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON;

	SELECT TypeId
		,NAME
		,NAME AS TypeName -- backup to old version
		,[Description]
	FROM dbo.AffType WITH (NOLOCK)
	WHERE IsShown=1
END
GO