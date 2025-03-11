/*<info serverAlias="DBAFFN88-Affiliate_N88, DBAFFN8G-Affiliate_N8G, DBAFFN8B-Affiliate_N8B" isFunction="0" isNested=""></info>*/
/*	
	Created: 20250311@Sophia
	Task: Remove Khmer/Cambodia [RedmineID: #219614]
	DB: DBAFFN88-Affiliate_N88, DBAFFN8G-Affiliate_N8G, DBAFFN8B-Affiliate_N8B
	 
*/
 

DELETE [Affiliate_N88].[dbo].[Market]  where MarketId = 'km-KH' 

DELETE [Affiliate_N8B].[dbo].[Market]  where MarketId = 'km-KH' 

DELETE [Affiliate_N8G].[dbo].[Market]  where MarketId = 'km-KH' 