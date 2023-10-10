 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Task_Aff_ClearLogin]
	
AS

/*
	Created:  20110221@Jamie
	Task: Clear Login
	DB: DB052.Affiliate_ZZun
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) AND (ServerID IN (200,201))


