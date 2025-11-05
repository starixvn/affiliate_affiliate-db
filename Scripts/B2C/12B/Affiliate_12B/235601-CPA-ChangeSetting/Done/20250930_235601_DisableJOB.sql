/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250930@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Disable Affiliate_12B: CPA Calculation Daily Job 
	RedmineID: #235601
	
*/

USE msdb;
GO

EXEC sp_update_job
    @job_name = N'Affiliate_12B: CPA Calculation Daily Job',
    @enabled = 0;
GO