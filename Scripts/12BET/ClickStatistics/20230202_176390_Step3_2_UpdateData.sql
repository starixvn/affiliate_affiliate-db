/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230202@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Update CountryCode3: "ROM, ANT" to CountryCode2: "RO, AG" [RedmineId : #176390]
	Explanation: ('ROMANIA', 'RO', 'ROM'), ('ANTIGUA AND BARBUDA', 'AG', 'ANT')
*/

--Update ClickStatistics1_bk
UPDATE c
SET c.Country = CASE WHEN c.Country = 'ROM' THEN 'RO'
					 WHEN c.Country = 'ANT' THEN 'AG'
					 ELSE c.Country
				END
FROM ClickStatistics1_bk c WITH (ROWLOCK, UPDLOCK)
WHERE c.Date >= '2020-08-01' AND c.Country IN ('ROM', 'ANT')

