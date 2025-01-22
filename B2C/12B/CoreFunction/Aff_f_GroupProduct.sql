/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_GroupProduct]
(
)
RETURNS TABLE
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function get group product

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

RETURN
	SELECT 71 AS ProductId, 71 AS GroupProductId
	UNION ALL
	SELECT 72, 71
GO
