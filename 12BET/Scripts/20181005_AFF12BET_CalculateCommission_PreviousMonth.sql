USE [Affiliate_12BET]
GO

/*
	Created: 20181005@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add old deduction setting
*/

DECLARE @MonthDate SMALLDATETIME = '2018-08-31'

INSERT INTO dbo.DeductionSettingHistory (GroupID, MonthDate, DeductionID, DeductedPercentage, ProductId)
SELECT GroupID, '2018-09-30' AS MonthDate, DeductionID, DeductedPercentage, ProductId
FROM dbo.DeductionSettingHistory WITH (NOLOCK)
WHERE DeductionID <= 9
	AND MonthDate = @MonthDate