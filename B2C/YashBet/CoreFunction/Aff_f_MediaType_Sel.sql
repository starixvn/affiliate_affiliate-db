/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_MediaType_Sel]
(
)
RETURNS TABLE
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function store Type on Media Gallery

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

RETURN
	SELECT TypeId, Type
	FROM (
		VALUES
			(1, 'Flash')
			,(2, 'Image')
	) AS MediaType (TypeId, Type)
GO