/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250903@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Step3-CreateTableTrackingCPA [RedmineID: #237540]
*/
USE Affiliate_12B
DROP TABLE IF EXISTS MemberCPA
DROP TABLE IF EXISTS MemberCPATier
DROP TABLE IF EXISTS MemberCPAProduct
DROP TABLE IF EXISTS MemberCPA_EOL

-- Create MemberCPA table
CREATE TABLE dbo.MemberCPA (
    MemberCPA_ID INT IDENTITY(1,1),
    AffId INT NOT NULL,
    CustId INT NOT NULL,
    GroupId INT NOT NULL,
    ActiveQualifiedDate DATETIME NULL,
    TotalDeposit MONEY NULL,
    Turnover MONEY NULL,
    BetTickets SMALLINT NULL,
    HoldingQualifiedDate DATETIME NULL,
    HoldingBetTickets SMALLINT NULL,
    HoldingExpiredDate DATETIME NULL,
    CPAAmount MONEY NULL,
    CPADate DATETIME NULL,
    StatusId SMALLINT NULL,
    Description VARCHAR(300) NULL,
    UpdatedDate DATETIME NULL,
    RefId BIGINT NULL,
	CONSTRAINT [PK_MemberCPA] PRIMARY KEY NONCLUSTERED 
(
	MemberCPA_ID ASC
) ON [ReportData]
) ON [ReportData]
GO

--Clustered
CREATE CLUSTERED INDEX CIX_MemberCPA_CustId_StatusId_AffId  
ON MemberCPA (CustId ASC, StatusId ASC, AffId ASC)
ON [ReportData]
GO

--NonClustered
--AQD
CREATE NONCLUSTERED INDEX IX_MemberCPA_ActiveQualifiedDate_GroupId_StatusId
ON MemberCPA (ActiveQualifiedDate ASC, GroupId ASC, StatusId ASC)
INCLUDE (AffId, CustId, CPAAmount, HoldingQualifiedDate, CPADate, TotalDeposit, HoldingBetTickets)
ON [ReportData]
GO

--HQD
CREATE NONCLUSTERED INDEX IX_MemberCPA_HoldingQualifiedDate_GroupId_StatusId  
ON MemberCPA (HoldingQualifiedDate ASC, GroupId ASC, StatusId ASC)
INCLUDE (AffId, CustId, CPAAmount, ActiveQualifiedDate, CPADate, TotalDeposit, HoldingBetTickets)
ON [ReportData]
GO

--CPADate
CREATE NONCLUSTERED INDEX IX_MemberCPA_CPADate_GroupId_StatusId
ON MemberCPA (CPADate ASC, GroupId ASC, StatusId ASC)
INCLUDE (AffId, CustId, CPAAmount, ActiveQualifiedDate, HoldingQualifiedDate, TotalDeposit, HoldingBetTickets)
ON [ReportData]
GO

-- Create MemberCPATier table (Detail by Group Product)
CREATE TABLE dbo.MemberCPATier (
    MemberCPATier_ID INT IDENTITY(1,1),
    MemberCPA_ID INT NOT NULL,
    AffId INT NOT NULL,
    CustId INT NOT NULL,
    GroupId INT NOT NULL,
    GroupProductId TINYINT NOT NULL,
    ActiveQualifiedDate DATETIME NULL,
    Turnover MONEY NULL,
    BetTickets SMALLINT NULL,
    CPAAmount MONEY NULL,
    UpdatedDate DATETIME NULL,
 CONSTRAINT [PK_MemberCPATier] PRIMARY KEY NONCLUSTERED 
(
	MemberCPATier_ID ASC
) ON [ReportData]
) ON [ReportData]
GO

--Clustered
CREATE CLUSTERED INDEX CIX_MemberCPATier_MemberCPA_ID 
ON MemberCPATier (MemberCPA_ID ASC) 
ON [ReportData]
GO

-- Create MemberCPAProduct table (Detail by Product)
CREATE TABLE dbo.MemberCPAProduct (
    MemberCPAProduct_ID INT IDENTITY(1,1),
    MemberCPATier_ID INT NOT NULL,
    MemberCPA_ID INT NOT NULL,
    AffId INT NOT NULL,
    CustId INT NOT NULL,
    GroupId INT NOT NULL,
    GroupProductId TINYINT NOT NULL,
    ProductId INT NOT NULL,
    Turnover MONEY NULL,
    ActiveQualifiedDate DATETIME NULL,
    BetTickets INT NULL,
    UpdatedDate DATETIME NULL,
 CONSTRAINT [PK_MemberCPAProduct] PRIMARY KEY NONCLUSTERED 
(
	MemberCPAProduct_ID ASC
) ON [ReportData]
) ON [ReportData]
GO

--Clustered
CREATE CLUSTERED INDEX CIX_MemberCPAProduct_MemberCPA_ID 
ON MemberCPAProduct (MemberCPA_ID ASC)
ON [ReportData]
GO


-- Create MemberCPA_EOL table
CREATE TABLE dbo.MemberCPA_EOL (
    CustId INT NOT NULL,
    AffId INT NOT NULL,
    GroupId INT NOT NULL,
    ActiveQualifiedDate DATETIME NULL,
    HoldingQualifiedDate DATETIME NULL,
    CreatedDate DATETIME NULL
) ON [ReportData]
GO

--Clustered
CREATE CLUSTERED INDEX CIX_MemberCPA_EOL_CustId
ON MemberCPA_EOL (CustId ASC)
ON [ReportData]
GO

