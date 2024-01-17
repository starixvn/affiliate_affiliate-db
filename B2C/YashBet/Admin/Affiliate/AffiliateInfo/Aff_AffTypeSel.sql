/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffTypeSel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Get list afftype

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
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