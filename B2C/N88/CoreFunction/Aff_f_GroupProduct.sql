/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GroupProduct]
(
)
RETURNS TABLE
AS

/*
	Created: 20241024@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core function get group product

	Revisions:
		- 20241024@Sally: Initialize SP [RedmineID: #199895]
*/

RETURN
	SELECT 71 AS ProductId, 71 AS GroupProductId
	UNION ALL
	SELECT 72, 71
GO
