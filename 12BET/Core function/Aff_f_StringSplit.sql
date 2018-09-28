/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_StringSplit]
(
	@String NVARCHAR(MAX),
	@Split	NVARCHAR(MAX)
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core function - Split string

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

RETURN
	WITH CTE_Split AS
	(
		SELECT 1 AS Id, CONVERT(BIGINT, 0) AS Index1, CHARINDEX(@Split, @String) AS Index2
		UNION ALL
		SELECT Id + 1, Index2 + LEN(@Split), CHARINDEX(@Split, @String, Index2 + LEN(@Split))
		FROM CTE_Split
		WHERE Index2 > 0
	)
	SELECT Id, SUBSTRING(@String, Index1, COALESCE(NULLIF(Index2, 0), LEN(@string) + 1) - Index1) AS val
	FROM CTE_Split
GO