/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION dbo.Aff_f_GetSpecialEmail()
RETURNS TABLE
AS
/*  
	Created: 20250320@Lewis  
	Task : Get special Email
	DB: DBAFF12B-Affiliate_12B  
  
	Revisions:
		- 20250320@Lewis: Initialize [RedmineID: #220971]
		
*/
RETURN
	SELECT Email
	FROM (
			VALUES ('12arpitasingh12@gmail.com')
		 ) A(Email)
GO