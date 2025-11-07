/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251008@lewis.cao
    DB: DBAFF12B-Affiliate_12B
    Task: Add FDM column to MemberCPA table and recreate with new structure [RedmineID: #235601]
    
    Purpose: Add FDM (First Deposit Minimum) column to MemberCPA table structure
    Business Context: Support FDM tracking for CPA commission calculations and tier qualifications
*/

USE Affiliate_12B
GO

-- Backup existing MemberCPA data
SELECT [AffId],
	[CustId],
	[GroupId],
	[ActiveQualifiedDate],
	[TotalDeposit],
	[Turnover],
	[BetTickets],
	[HoldingQualifiedDate],
	[HoldingBetTickets],
	[HoldingExpiredDate],
	[CPAAmount],
	[CPADate],
	[StatusId],
	[Description],
	[RefId],
	[UpdatedDate]
INTO memberCPA_bk
FROM MemberCPA
GO

-- Drop existing table
DROP TABLE MemberCPA
GO

-- Create new MemberCPA table with FDM column
CREATE TABLE [dbo].[MemberCPA](
	[MemberCPA_ID] [int] IDENTITY(1,1) NOT NULL,
	[AffId] [int] NOT NULL,
	[CustId] [int] NOT NULL,
	[GroupId] [int] NULL,
	[ActiveQualifiedDate] [datetime] NULL,
	FDM [money] NULL,
	[TotalDeposit] [money] NULL,
	[Turnover] [money] NULL,
	[BetTickets] [smallint] NULL,
	[HoldingQualifiedDate] [datetime] NULL,
	[HoldingBetTickets] [smallint] NULL,
	[HoldingExpiredDate] [datetime] NULL,
	[CPAAmount] [money] NULL,
	[CPADate] [datetime] NULL,
	[StatusId] [smallint] NULL,
	[Description] [varchar](300) NULL,
	[RefId] [bigint] NULL,
	[FirstDepositDate] [datetime] NULL,
	[ExpiredRedepositDate] [datetime] NULL,
	[IsRedeposit] [bit] NULL,
	[UpdatedDate] [datetime] NULL,
 CONSTRAINT [PK_MemberCPA] PRIMARY KEY NONCLUSTERED 
(
	[MemberCPA_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [ReportData]
GO

-- Create clustered index
CREATE CLUSTERED INDEX [CIX_MemberCPA_CustId] ON [dbo].[MemberCPA]
(
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO


--NonClustered
--AQD
CREATE NONCLUSTERED INDEX IX_MemberCPA_ActiveQualifiedDate_AffId_GroupId_StatusId
ON MemberCPA (ActiveQualifiedDate ASC, AffId ASC, GroupId ASC, StatusId ASC)
INCLUDE ( CustId, CPAAmount, HoldingQualifiedDate, CPADate, TotalDeposit, HoldingBetTickets)
ON [ReportData]
GO

--HQD
CREATE NONCLUSTERED INDEX IX_MemberCPA_HoldingQualifiedDate_AffId_GroupId_StatusId  
ON MemberCPA (HoldingQualifiedDate ASC, AffId ASC, GroupId ASC, StatusId ASC)
INCLUDE ( CustId, CPAAmount, ActiveQualifiedDate, CPADate, TotalDeposit, HoldingBetTickets)
ON [ReportData]
GO

--CPADate
CREATE NONCLUSTERED INDEX IX_MemberCPA_CPADate_AffId_GroupId_StatusId
ON MemberCPA (CPADate ASC, AffId ASC, GroupId ASC, StatusId ASC)
INCLUDE ( CustId, CPAAmount, ActiveQualifiedDate, HoldingQualifiedDate, TotalDeposit, HoldingBetTickets)
ON [ReportData]
GO


GO