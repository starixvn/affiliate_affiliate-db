 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER PROCEDURE [dbo].[Task_Aff_ClearLogin_Loop]  
AS  
/*
	Created:  20110221@Jamie
	Task: Clear Login
	DB: DB052.Affiliate_ZZun
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON

EXEC Task_Aff_ClearLogin 


declare @TaskID int,@LogID int , @RunDate datetime, @Status varchar(50)

select @RunDate=getdate(), @Status='completed'

select @TaskID= TaskID from TaskManager(nolock) where TaskName='Clear Login'
exec [dbo].[Aff_TaskLogIns]
	@TaskID,
	@RunDate,
	@Status,
	@LogID OUTPUT


/*
 Declare @start datetime  
 SELECT @start = CURRENT_TIMESTAMP  
  
 WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)  
 BEGIN  
  EXEC Task_Aff_ClearLogin  
  WAITFOR DELAY '00:00:30'  
 END  
 
 */
