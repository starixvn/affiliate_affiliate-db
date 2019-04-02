/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_3rdProduct_ImportQueueSel]
    @ProductId INT,
    @FromDate   DATETIME,
    @ToDate   DATETIME,
    @JobType TINYINT = 0
AS
/*
	Created: 20190327@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get Importing Information

	Revisions:
		- Created: 20190327@Walter: Initialize SP [RedmineID: #110638]
*/
BEGIN
    SELECT QueueId, CheckInTime, FinishedTime, WinlostDate, LogDesc
    FROM [dbo].[APIProduct_ImportQueue] WITH (NOLOCK)
    WHERE ProductId = @ProductId AND 
        CheckInTime >= @FromDate AND CheckInTime <= @ToDate AND 
        JobType = ISNULL(@JobType, 0)
    ORDER BY CheckInTime DESC
END
GO