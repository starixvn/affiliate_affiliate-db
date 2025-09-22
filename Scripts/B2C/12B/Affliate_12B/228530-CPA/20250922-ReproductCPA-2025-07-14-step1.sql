/*<info serverAlias="DB12B-bodb_12B" ></info>*/
/*  
	Created: 20250922@Lewis
	DB: DB12B-bodb_12B
	Task: step 1 Tag + Customer repull [RedmineID: #239263]
*/

USE bodb_12B
GO

-- Customer
DELETE FROM dbo.API_TimeTracker WITH(UPDLOCK) WHERE DataSource = 'Customer' ;
GO
INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT DataSource,'2025-09-21 00:00:00' as CalledTime, KeyValue
FROM (
	SELECT 'Customer'AS DataSource,	'2025-07-01T00:00:00.000' AS KeyValue
)t 
GO