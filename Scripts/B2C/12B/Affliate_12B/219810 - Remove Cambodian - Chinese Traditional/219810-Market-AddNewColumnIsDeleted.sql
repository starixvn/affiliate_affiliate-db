/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250214@Lewis	
	Task: Remove Cambodian & Chinese Traditional
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250214@Lewis: Created [RedmineID: #219810]

	Description: km-KH ==> Cambodian kh || zh-TW ==> Chinese Traditional ch	

		Update ==> en-US	English	English	en	English
*/
-- ====================
-- Market
-- ====================

ALTER TABLE Market ADD IsDeleted BIT CONSTRAINT DF_Market_IsDeleted DEFAULT 0

UPDATE Market WITH (ROWLOCK,UPDLOCK) SET IsDeleted = 0

UPDATE m SET m.IsDeleted = 1 
FROM Market m WITH (ROWLOCK,UPDLOCK)
WHERE MarketId IN ('zh-TW','km-KH','hi-IN')
