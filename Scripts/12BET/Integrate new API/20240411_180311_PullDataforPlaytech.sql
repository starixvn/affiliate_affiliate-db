/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240411@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Pull data for 12Emerald Playtech [RedmineId : #180311]
*/

;WITH CTE_Pull AS
(
	SELECT TOP(1) Id
	FROM APIProduct_TimeTracker WITH (NOLOCK)
	WHERE TpType = 1 -- 12Emerald Playtech
	ORDER BY Id DESC
)
UPDATE tt
SET tt.CallTime = '2024-03-01'
FROM APIProduct_TimeTracker tt WITH (ROWLOCK, UPDLOCK)
	INNER JOIN CTE_Pull ctp ON tt.Id = ctp.Id
GO