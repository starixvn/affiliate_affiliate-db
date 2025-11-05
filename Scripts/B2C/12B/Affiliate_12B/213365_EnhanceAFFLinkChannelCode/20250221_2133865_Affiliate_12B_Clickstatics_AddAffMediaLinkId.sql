/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250218@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Enhance AFF Media Channel [RedmineID: #212201]
		-  Add new column ChannelCode

*/

USE Affiliate_12B
GO

ALTER TABLE [Affiliate_12B].dbo.[MemberInfo]
ADD AffMediaLinkId INT NULL
GO

ALTER TABLE [Affiliate_12B].dbo.[AffMediaLink]
ADD AffMediaLinkId INT IDENTITY(1,1) NOT NULL
GO
CREATE UNIQUE INDEX CIX_UQ_AffMediaLink_AffMediaLinkId
ON [Affiliate_12B].dbo.[AffMediaLink] (AffMediaLinkId)
GO
---Add setting Cutofdate marketing clickstatistics report
INSERT INTO [Affiliate_12B].dbo.SystemSettings (SName, SValue)
SELECT t.SName, t.SValue
FROM(
	SELECT 'ReportMarketingStatistics_CutOffDate' AS SName, '2025-03-04 00:00:00' AS SValue
)AS t 
	LEFT JOIN dbo.SystemSettings s ON t.SName = s.SName
WHERE s.SName IS NULL