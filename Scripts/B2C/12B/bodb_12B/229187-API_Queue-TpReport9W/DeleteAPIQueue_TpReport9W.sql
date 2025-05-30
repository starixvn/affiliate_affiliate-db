/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250530@Lewis
	DB: DB12B-bodb_12B
	Task: DELETE API_Queue - Data Source = 'TpReport9W' [RedmineID: #229187]

*/

USE bodb_12B
GO

DELETE 
FROM API_Queue WITH (ROWLOCK)
WHERE DataSource = 'TpReport9W' AND CheckInTime >= '2025-05-29'