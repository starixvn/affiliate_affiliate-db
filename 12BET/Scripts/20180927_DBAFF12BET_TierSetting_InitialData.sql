USE [Affiliate_12BET]
GO

/*
	Created: 20180927@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Migrate data to new table - TierSettingHistory
*/

DECLARE @MonthDate SMALLDATETIME = '2018-09-30'

DECLARE @Groups TABLE (GroupId INT)
INSERT INTO @Groups (GroupId)
SELECT DISTINCT GroupId FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate = @MonthDate

INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
SELECT t.GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
FROM dbo.TierSetting t WITH (NOLOCK)
	LEFT JOIN @Groups g ON t.GroupId = g.GroupId
WHERE g.GroupId IS NULL