/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet,bodbDownlineNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GroupProduct] ()
RETURNS TABLE
AS

/*
	Created: 20211207@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core function - Group Product

	Revisions:
		- 20211207@Percy: Initialize function [RedmineID: #165777]
		- 20220601@Malcolm: Add bitcoin [RedmineID: #172701]
*/

RETURN
	-- SB
	SELECT
		CONVERT(INT, 1)						AS ProductId
		,CONVERT(VARCHAR(50), 'Sportsbook') AS ProductName
		,CONVERT(VARCHAR(20), 'SB')			AS ProductPrefix
		,CONVERT(INT, 1)					AS GroupProductId
		,CONVERT(VARCHAR(50), 'Sportsbook') AS GroupProductName
		,CONVERT(VARCHAR(20), 'SB')			AS GroupProductPrefix
	UNION ALL SELECT 33, 'Sports Lottery', 'SLT', 1, 'Sportsbook', 'SB' -- Sports Lottery
	UNION ALL SELECT 36, 'Bitcoin', 'BTC', 1, 'Sportsbook', 'SB' -- Bitcoin
GO