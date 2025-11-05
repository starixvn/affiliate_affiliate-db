/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250930@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Create rptAffiliateCPA table for CPA commission reporting
	RedmineID: #235601
	
	Purpose: Create rptAffiliateCPA table to store CPA commission report data
	Business Context: Support CPA reporting with deposit tracking and commission adjustments
*/
USE Affiliate_12B
GO
-- Create rptAffiliateCPA table
CREATE TABLE dbo.rptAffiliateCPA (
    Id INT IDENTITY(1,1) CONSTRAINT PK_rptAffiliateCPA_Id PRIMARY KEY NONCLUSTERED,
    StartSchedule DATE NOT NULL,
    EndSchedule DATE NOT NULL,
    AffId INT NOT NULL,
    GroupId INT NOT NULL,
    Status VARCHAR(50) NOT NULL,
    ExpiredRedepositDate DATETIME NULL,
    TotalEligiblePlayers INT NOT NULL CONSTRAINT DF_rptAffiliateCPA_TotalEligiblePlayers DEFAULT (0),
    TotalRedepositPlayers INT NOT NULL CONSTRAINT DF_rptAffiliateCPA_TotalRedepositPlayers DEFAULT (0),
    EstimateAmount MONEY NULL,
    ApprovedAmount MONEY NULL,
    ApprovedDate DATE NULL,
    AdjustedAmount MONEY NULL,
    AdjustedDate DATE NULL,
    Description NVARCHAR(300) NULL,
    AdjustedBy INT NULL,
	IsProcessed BIT NOT NULL CONSTRAINT DF_rptAffiliateCPA_IsProcessed DEFAULT (0),
    UpdatedDate DATETIME NULL
) ON [ReportData]

-- clustered index
CREATE UNIQUE CLUSTERED INDEX CIX_rptAffiliateCPA_AffId_GroupId_EndSchedule_StartSchedule
ON dbo.rptAffiliateCPA (AffId, GroupId, EndSchedule, StartSchedule) ON [ReportData];

-- Index date-based queries
CREATE NONCLUSTERED INDEX IX_rptAffiliateCPA_EndSchedule_GroupId_Status
ON dbo.rptAffiliateCPA (EndSchedule, GroupId, Status )
INCLUDE (Id, ApprovedDate, AdjustedDate, TotalEligiblePlayers, TotalRedepositPlayers, EstimateAmount, ApprovedAmount, AdjustedAmount, ExpiredRedepositDate, Description, AdjustedBy) ON [ReportData]
;
-- Index date-based queries
CREATE NONCLUSTERED INDEX IX_rptAffiliateCPA_ApprovedDate_GroupId_Status
ON dbo.rptAffiliateCPA (ApprovedDate, GroupId, Status)
INCLUDE (Id, EndSchedule, AdjustedDate, TotalEligiblePlayers, TotalRedepositPlayers, EstimateAmount, ApprovedAmount, AdjustedAmount, ExpiredRedepositDate, Description, AdjustedBy) ON [ReportData]
;

-- Index date-based queries
CREATE NONCLUSTERED INDEX IX_rptAffiliateCPA_AdjustedDate_GroupId_Status
ON dbo.rptAffiliateCPA (AdjustedDate, GroupId, Status)
INCLUDE (Id, ApprovedDate, EndSchedule, TotalEligiblePlayers, TotalRedepositPlayers, EstimateAmount, ApprovedAmount, AdjustedAmount, ExpiredRedepositDate, Description, AdjustedBy) ON [ReportData]
;
-- Verification: Check table structure
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'rptAffiliateCPA'
ORDER BY ORDINAL_POSITION ASC