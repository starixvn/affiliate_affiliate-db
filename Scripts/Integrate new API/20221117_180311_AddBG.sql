/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221202@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update Job

*/


INSERT INTO dbo.Products 
(
	ProductId
	,ProductName
	,ProductPrefix
	,IsIBC
	,TransferType
	,Enabled
	,IsTest
	,EndOfSupportDate
	,ReleasedDate
)

VALUES (40, '12Zircon - BG', 'BG', 0, 0, 1, 0, NULL, '2022-12-01')
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (40, 'LastQueueId', '0')
	,(40, 'LaunchDate', '2022-12-01')
	,(40, 'SourceTable', 'APIProduct_ImportQueue')
	,(40, 'TimeZone', '8')
    ,(40, 'TicketStatus', '')
GO

INSERT INTO dbo.DeductionSetting (GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,ProductId,GroupProductId,NextGroupProductId)
SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,40,GroupProductId,NextGroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,GroupProductId,NextGroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO

INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage,ProductId,GroupProductId)
SELECT GroupID,'2022-12-31',DeductionID,DeductedPercentage,40,GroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,GroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO
