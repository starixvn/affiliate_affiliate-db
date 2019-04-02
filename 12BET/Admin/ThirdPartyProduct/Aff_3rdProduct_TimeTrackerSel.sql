/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_3rdProduct_TimeTrackerSel]
    @ProductId INT,
    @FromDate   DATETIME,
    @ToDate   DATETIME
AS
/*
	Created: 20190327@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get Importing Information

	Revisions:
		- Created: 20190327@Walter: Initialize SP [RedmineID: #110638]
*/
BEGIN
    SELECT Currency, CallTime
    FROM [dbo].[APIProduct_TimeTracker] WITH (NOLOCK)
    WHERE ProductId = @ProductId AND 
        CallTime >= @FromDate AND CallTime <= @ToDate
    ORDER BY CallTime DESC
END
GO