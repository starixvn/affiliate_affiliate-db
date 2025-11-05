/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20251015@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Drop and recreate MemberCPA_EOL table with new structure
	RedmineID: #235601
	
	Purpose: Recreate MemberCPA_EOL table with updated column structure and clustered index on CustId
	Business Context: Update table structure to support enhanced CPA tracking with new columns
*/

USE Affiliate_12B
GO

-- Drop existing table if exists
IF OBJECT_ID('dbo.MemberCPA_EOL', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.MemberCPA_EOL
    PRINT 'Dropped existing MemberCPA_EOL table'
END
GO

-- Create MemberCPA_EOL table with new structure
CREATE TABLE dbo.MemberCPA_EOL (
    CustId INT NOT NULL CONSTRAINT PK_MemberCPA_EOL_CustId PRIMARY KEY CLUSTERED,
    AffId INT NOT NULL,
    GroupId INT NOT NULL,
    ActiveExpiredDate DATETIME NULL,
    FDM MONEY NULL,
    TotalDeposit MONEY NULL,
    Turnover MONEY NULL,
    BetTickets SMALLINT NULL,
    HoldingExpiredDate DATETIME NULL,
    CreatedDate DATETIME NULL
)
GO

