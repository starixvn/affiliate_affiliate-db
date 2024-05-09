/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_StringSplit]
(
	@String NVARCHAR(MAX),
	@Split	NVARCHAR(MAX)
)
RETURNS TABLE
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function - Split string

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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
	,CTE_Result AS
	(
		SELECT Id, SUBSTRING(@String, Index1, COALESCE(NULLIF(Index2, 0), LEN(@string) + 1) - Index1) AS val
		FROM CTE_Split
		WHERE SUBSTRING(@String, Index1, COALESCE(NULLIF(Index2, 0), LEN(@string) + 1) - Index1) <> ''
	)
	SELECT ROW_NUMBER() OVER(ORDER BY Id) AS Id, val
	FROM CTE_Result
GO