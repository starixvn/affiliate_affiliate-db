CREATE PROCEDURE [dbo].[Task_Aff_ClearLogin_Loop]  
AS  
/*
	Created:  20110221@Jamie
	Task: Clear Login
	DB: DB052.Affiliate_12BET
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
 Declare @start datetime  
 SELECT @start = CURRENT_TIMESTAMP  
  
 WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)  
 BEGIN  
  EXEC Task_Aff_ClearLogin  
  WAITFOR DELAY '00:00:30'  
 END  
 

