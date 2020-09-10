/*<info serverAlias="DBAFFN88-msdb"></info>*/

/*
	Created: 20200910@Percy
	DB: DBAFFN8x (DB052)
	Task: Remove code get data on bettrans
*/

-- Remove step check & correct data
	-- This step just get data on bettrans but data is not get on bettrans anymore --> remove this step
use msdb
go

exec dbo.sp_delete_jobstep
	@job_name = 'Affiliate_N88: Generate Data Daily'
	,@step_id = 2
go

exec dbo.sp_delete_jobstep
	@job_name = 'Affiliate_N8B: Generate Data Daily'
	,@step_id = 2
go

exec dbo.sp_delete_jobstep
	@job_name = 'Affiliate_N8G: Generate Data Daily'
	,@step_id = 2
go


-- Remove unused SPs --> rename SPs first
use Affiliate_N88
go
exec sp_rename 'Aff_f_MediaCurrency_Sel', 'DEL_Aff_f_MediaCurrency_Sel'
exec sp_rename 'Task_Aff_ImportData_3rdProducts', 'DEL_Task_Aff_ImportData_3rdProducts'
exec sp_rename 'Task_Aff_ImportData_CheckData', 'DEL_Task_Aff_ImportData_CheckData'
exec sp_rename 'Task_Aff_ImportData_CheckData_Job', 'DEL_Task_Aff_ImportData_CheckData_Job'
go

use Affiliate_N8B
go
exec sp_rename 'Aff_f_MediaCurrency_Sel', 'DEL_Aff_f_MediaCurrency_Sel'
exec sp_rename 'Task_Aff_ImportData_3rdProducts', 'DEL_Task_Aff_ImportData_3rdProducts'
exec sp_rename 'Task_Aff_ImportData_CheckData', 'DEL_Task_Aff_ImportData_CheckData'
exec sp_rename 'Task_Aff_ImportData_CheckData_Job', 'DEL_Task_Aff_ImportData_CheckData_Job'
go

use Affiliate_N8G
go
exec sp_rename 'Aff_f_MediaCurrency_Sel', 'DEL_Aff_f_MediaCurrency_Sel'
exec sp_rename 'Task_Aff_ImportData_3rdProducts', 'DEL_Task_Aff_ImportData_3rdProducts'
exec sp_rename 'Task_Aff_ImportData_CheckData', 'DEL_Task_Aff_ImportData_CheckData'
exec sp_rename 'Task_Aff_ImportData_CheckData_Job', 'DEL_Task_Aff_ImportData_CheckData_Job'
go