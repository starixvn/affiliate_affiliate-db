
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)

SELECT 10, 'LastQueueId', '1' UNION ALL
SELECT 10, 'LaunchDate', '2018-10-01' UNION ALL
SELECT 10, 'SourceTable', 'APIProduct_ImportQueue' UNION ALL

SELECT 11, 'LastQueueId', '1' UNION ALL
SELECT 11, 'LaunchDate', '2018-10-01' UNION ALL
SELECT 11, 'SourceTable', 'APIProduct_ImportQueue'