/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_3rdProduct_XmlDataByQueueIdSel]
    @QueueId INT
AS
/*
	Created: 20190327@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get Importing Information

	Revisions:
		- Created: 20190327@Walter: Initialize SP [RedmineID: #110638]
*/
BEGIN
    SELECT TOP 1 XmlData
    FROM [dbo].[APIProduct_ImportQueue] WITH (NOLOCK)
    WHERE QueueId = @QueueId
END
GO