/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250512@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #227030]
*/

--Market
update m set m.Language ='Bengali'
FROM MediaGallery m WITH (ROWLOCK,UPDLOCK)
WHERE language = 'English (Bangladesh)'
GO

