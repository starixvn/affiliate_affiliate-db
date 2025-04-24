/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20250422@Sally
	DB: DBAFFN88-Affiliate_N88
	Task: Add Korean and Portuguese language [RedmineID: #225075]

*/

USE Affiliate_N88
GO
INSERT INTO [dbo].[Market]
           ([MarketId]
           ,[MarketName]
           ,[MarketNativeName]
           ,[ShortedCode]
           ,[DisplayName])
SELECT t.[MarketId]
    , t.[MarketName]
    , t.[MarketNativeName]
    , t.[ShortedCode]
    , t.[DisplayName]
FROM (
	SELECT 'ko-KR' AS [MarketId], 'Korean' AS [MarketName], N'한국어' AS [MarketNativeName], 'ko' AS [ShortedCode], 'Korean' AS [DisplayName]
	UNION ALL
	SELECT 'pt-BR' AS [MarketId], 'Portuguese' AS [MarketName], N'Português' AS [MarketNativeName], 'br'[ShortedCode], 'Portuguese' AS [DisplayName]
)t
	LEFT JOIN dbo.Market m WITH(NOLOCK) ON m.MarketId = t.MarketId
WHERE m.MarketId IS NULL
