ALTER PROCEDURE [dbo].[Task_Aff_ClearLogin]
	
AS

/*
	Created:  20110221@Johnny
	Task: Clear Login
	DB: DB052.Affiliate_12BET
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP)


