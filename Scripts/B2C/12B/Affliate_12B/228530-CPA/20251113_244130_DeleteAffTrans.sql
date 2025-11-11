/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251111@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Reproduct CPA 15-07 [RedmineID: #244130]
*/


USE Affiliate_12B

--AffTrans --4 rows affected
DELETE AffTrans WITH (ROWLOCK)
WHERE AffId IN  (92043851,92043853) AND TransType = 206

