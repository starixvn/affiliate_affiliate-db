/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250930@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Update Schedule ID 5 to set IntervalType = 'Day' and IntervalValue = 30
	RedmineID: #235601
	
	Purpose: Update schedule configuration for ScheduleId = 5
	Change from Monthly (Month, 1) to Every 30 days (Day, 30)
*/

USE Affiliate_12B
GO

    UPDATE dbo.Schedule 
    SET IntervalType = 'Day',
        IntervalValue = 30
    WHERE ScheduleId = 5
