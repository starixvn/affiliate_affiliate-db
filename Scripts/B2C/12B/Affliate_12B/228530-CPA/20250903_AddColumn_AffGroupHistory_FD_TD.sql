/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250903@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: AffGroupHistory.Fromdate-Todate [RedmineID: #237540]
*/

USE Affiliate_12B

-- AffGroupHistory: Add FromDate, ToDate columns
ALTER TABLE AffGroupHistory
ADD FromDate datetime NULL,
    ToDate datetime NULL;
GO

-- Index
CREATE NONCLUSTERED INDEX IX_AffGroupHistory_AffId_ToDate
ON dbo.AffGroupHistory (AffId)
INCLUDE (GroupId)
WHERE ToDate = '9999-12-31';
GO
-- Init data for 2 columns

DECLARE @CurrentMonth DATETIME = EOMONTH(GETDATE());
DECLARE @ProcessingMonth DATETIME;
DECLARE @MonthStart DATETIME;
DECLARE @MonthEnd DATETIME;

DECLARE @TotalMonths INT;
DECLARE @CurrentIndex INT = 1;


-- Create temp table with distinct months that need processing
CREATE TABLE #MonthsToProcess (
    MonthDate DATETIME,
    ProcessOrder INT IDENTITY(1,1)
);

INSERT INTO #MonthsToProcess (MonthDate)
SELECT DISTINCT MonthDate
FROM AffGroupHistory WITH (NOLOCK)
ORDER BY MonthDate;

SELECT @TotalMonths = COUNT(MonthDate) 
FROM #MonthsToProcess

-- Process each month using WHILE loop
WHILE @CurrentIndex <= @TotalMonths
BEGIN
    -- Get the month to process
    SELECT @ProcessingMonth = MonthDate 
    FROM #MonthsToProcess 
    WHERE ProcessOrder = @CurrentIndex;
    
    -- Calculate month boundaries
    SET @MonthStart = DATEADD(DAY, 1, EOMONTH(@ProcessingMonth, -1));
    SET @MonthEnd = @ProcessingMonth;
        
        -- Check if this is current month
        IF @ProcessingMonth = @CurrentMonth
        BEGIN
            -- Current month: FromDate = first day of month, ToDate = '9999-12-31'
			--SELECT * FROM AffGroupHistory
            UPDATE AffGroupHistory WITH (UPDLOCK, ROWLOCK)
            SET FromDate = @MonthStart,
                ToDate = '9999-12-31'
            WHERE MonthDate = @ProcessingMonth
             -- AND (FromDate IS NULL OR ToDate IS NULL);
              
        END
        ELSE
        BEGIN
            -- Past months: FromDate = first day of month, ToDate = last day of month
			--SELECT * FROM AffGroupHistory
            UPDATE AffGroupHistory WITH (UPDLOCK, ROWLOCK)
            SET FromDate = @MonthStart,
                ToDate = @MonthEnd
            WHERE MonthDate = @ProcessingMonth
            --  AND (FromDate IS NULL OR ToDate IS NULL);
              
        END 
    
    -- Move to next month
    SET @CurrentIndex = @CurrentIndex + 1;
END

-- Cleanup temp table
DROP TABLE #MonthsToProcess;

GO
