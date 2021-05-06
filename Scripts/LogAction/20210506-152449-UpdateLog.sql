/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*  
Created: 20210506@Malcolm
Task : Update Currency [RedmineId : #152957]
*/
USE Affiliate_12BET
GO

UPDATE dbo.UserLog_RunSP_Detail WITH(ROWLOCK)
	SET NewData = REPLACE(NewData,'Currency="INH"', 'Currency="VND"' )
WHERE SPName = 'Aff_CustomerInsMember' AND NewData LIKE '%Currency="INH"%'



