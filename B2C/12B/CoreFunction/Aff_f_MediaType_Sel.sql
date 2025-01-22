/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_MediaType_Sel]
(
)
RETURNS TABLE
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function store Type on Media Gallery

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

*/

RETURN
	SELECT TypeId, Type
	FROM (
		VALUES
			(1, 'Flash')
			,(2, 'Image')
	) AS MediaType (TypeId, Type)
GO