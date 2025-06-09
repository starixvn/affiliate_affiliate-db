/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250514@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Add more messages and CutofDate commission [RedmineID: #226985]

*/

-- insert new row in table SystemSettings with sname = 'CommissionCal_CutoffDate' and svalue = '2025-05-01'
INSERT INTO SystemSettings (sname, svalue) 
SELECT t.sname, t.svalue
FROM(
    SELECT 'CommissionCal_CutOffDate' AS sname, '2025-05-01' AS svalue
) AS t
    LEFT JOIN dbo.SystemSettings s WITH (NOLOCK) ON t.sname = s.sname
WHERE s.sname IS NULL
GO

INSERT INTO Messages (
			[MessageId]
           ,[MessageTypeId]
           ,[Description]
           ,[MessageContentBN]
           ,[MessageContentENEURO]
           ,[MessageContentEN]
           ,[MessageContentHIEN]
           ,[MessageContentID]
           ,[MessageContentJP]
           ,[MessageContentKH]
           ,[MessageContentKO]
           ,[MessageContentTH]
           ,[MessageContentVN]
           ,[MessageContentCS]
)	
SELECT t.MessageId
    ,10 AS [MessageTypeId]
    ,MessageContent AS [Description]
    ,MessageContent AS [MessageContentBN]
    ,MessageContent AS [MessageContentENEURO]
    ,MessageContent AS [MessageContentEN]
    ,MessageContent AS [MessageContentHIEN]
    ,MessageContent AS [MessageContentID]
    ,MessageContent AS [MessageContentJP]
    ,MessageContent AS [MessageContentKH]
    ,MessageContent AS [MessageContentKO]
    ,MessageContent AS [MessageContentTH]
    ,MessageContent AS [MessageContentVN]
    ,MessageContent AS [MessageContentCS]
FROM(
	SELECT 1010 AS MessageId, N'The first Tier of the Min Net Win column must be = 0 or -∞' AS MessageContent
	UNION ALL
	SELECT 1011 AS MessageId, N'The next Tier after a negative Tier must start from 1 in the Min Net Win column.' AS MessageContent
	UNION ALL
	SELECT 1012 AS MessageId,N'The values in the Min Net Win column must increase sequentially.'AS MessageContent
) AS t
	LEFT JOIN dbo.Messages m WITH (NOLOCK) ON t.MessageId = m.MessageId
WHERE m.MessageId IS NULL

