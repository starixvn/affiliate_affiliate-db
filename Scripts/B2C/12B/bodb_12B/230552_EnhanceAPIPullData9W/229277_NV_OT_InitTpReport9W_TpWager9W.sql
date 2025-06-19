/*<info serverAlias="DBN88-bodb_N88, DB12B-bodb_12B" isFunction="0" isNested=""></info>*/
/*	
	Created: 20250046@Sally
	Task: Enhance API_TpReport9W_Get, API_TpWager9W_Get [RedmineID: #229277]
	DB: DBN88-bodb_N88, DB12B-bodb_12B
	- Init new Tracker for TpReport9W,TpWager9W

	USE bodb_N88
	GO

	USE bodb_12B
	GO
*/

/*Run ON DB052, DB053*/

DECLARE @DateTime SMALLDATETIME = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)

DELETE att
FROM dbo.API_TimeTracker att WITH (ROWLOCK, UPDLOCK)
WHERE att.CalledTime >='2025-06-04'
AND att.DataSource IN( 'TpReport9W', 'TpWager9W')


INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT 'TpReport9W' AS DataSource, @DateTime AS CalledTime, '{"SQ":1,"UpdateTime":"2025-06-16T00:00:00"}'  AS KeyValue
UNION ALL
SELECT 'TpWager9W' AS DataSource, @DateTime AS CalledTime, '{"CreateTime":"2025-01-01T00:00:00","UpdateTime":"2025-06-16T00:00:00"}'  AS KeyValue

GO


