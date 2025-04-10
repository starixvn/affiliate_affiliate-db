/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250321@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Enhance Get BBF by TimeZone [RedmineID: #222352]

*/

USE Affiliate_12B
GO

ALTER TABLE dbo.AffTrans
ADD WinlostDate SMALLDATETIME  NULL 
GO

SELECT COUNT(1) FROM dbo.AffTrans WITH(NOLOCK)-- ~ 1k2 rows

-- Update data on WinlostDate column on table AffTrans: get from data TransDate column(timezone GMT-4) change to timezone GMT+8 and then only get DATE only
UPDATE dbo.AffTrans WITH(ROWLOCK, UPDLOCK)
SET WinlostDate = CAST(CONVERT(VARCHAR(10), DATEADD(HOUR, 12, TransDate), 120) AS SMALLDATETIME)
WHERE WinlostDate IS NULL
GO
-- add contrainst to WinlostDate column on table AffTrans default value getdate()
ALTER TABLE dbo.AffTrans
ADD CONSTRAINT DF_AffTrans_WinlostDate DEFAULT CAST(GETDATE() AS DATE) FOR WinlostDate
GO
    -- update column WinlostDate to not null
    ALTER TABLE dbo.AffTrans
    ALTER COLUMN WinlostDate SMALLDATETIME NOT NULL
GO
-- Create new non-index on AffTrans table
CREATE NONCLUSTERED INDEX IX_AffTrans_AffId_WinlostDate_Status
ON dbo.AffTrans (AffId, WinlostDate, [Status])
WITH ( PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
ON [TransactionIndex ]
GO
