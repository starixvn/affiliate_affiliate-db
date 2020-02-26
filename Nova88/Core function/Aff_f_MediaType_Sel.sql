/*<info serverAlias="DBAFFN8G-Affiliate_N8G" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_MediaType_Sel]
(
)
RETURNS TABLE
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Core function store Type on Media Gallery

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

RETURN
	SELECT TypeId, Type
	FROM (
		VALUES
			(1, 'Flash')
			,(2, 'Image')
	) AS MediaType (TypeId, Type)
GO