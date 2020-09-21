/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffTypeSel]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Get list afftype

	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
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