/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_Report_PlayerCPA
	@UserName NVARCHAR(100) = ''
	,@CustName NVARCHAR(100) = ''
	,@DealName NVARCHAR(MAX) = '' --list groupids
	,@StatusId VARCHAR(MAX) = ''
	,@Viewby TINYINT = 1
	,@FromDate DATETIME = ''
	,@ToDate DATETIME = ''
	,@NRows INT = 0 OUTPUT
/*
	Created:      20250721@Lewis
	Task:         Player CPA Report
	DB:           DBAFF12B-Affiliate_12B
	Revisions:
		- 20250721@Lewis: Initial [RedmineID: #228530]
		- 20251002@Lewis: Get info RedepositCondition [RedmineID: #240524]
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @Deals TABLE (GroupId INT)
	INSERT INTO @Deals (GroupId)
	SELECT CAST(f.value AS INT)
	FROM string_split(@DealName,',') f

	DECLARE @Status TABLE (StatusId SMALLINT)
	INSERT INTO @Status (StatusId)
	SELECT CAST(f.value AS SMALLINT)
	FROM string_split(@StatusId,',') f

	DECLARE @Tdate DATETIME = '9999-12-31'

	-- TODO: Implement Player CPA Report logic here
	CREATE TABLE #data (
		MemberCPA_ID INT
		, AffId INT
		, AffUsername VARCHAR(100)
		, CustId INT
		, CustUsername VARCHAR(100)
		, RegisteredDate DATETIME
		, GroupId INT
		, Dealname VARCHAR(100)
		, ScheduleId SMALLINT
		, ScheduleName VARCHAR(100)
		--Active
		, FTD MONEY
		, IsFTD BIT
		, TotalDeposit MONEY
		, IsTotalDeposit BIT
		, IsTO BIT
		, AQD DATETIME
		, CPAAmount MONEY
		--Holding
		, IsHolding BIT
		, HoldingBetTickets SMALLINT
		, HoldingTickets SMALLINT
		, HQD DATETIME
		, HED DATETIME
		, EstimatedCPAAmount MONEY
		--Redeposit
		, FirstDepositDate DATETIME
		, ReDepositDays INT
		, ExpiredRedepositDate DATETIME
		, IsRedeposit BIT
		--Approval
		, StatusId SMALLINT
		, IsAbnormal BIT
		, Description VARCHAR(300)
		, UpdatedDate DATETIME
	)
	INSERT INTO #data(
		MemberCPA_ID
		, AffId
		, AffUsername
		, CustId
		, CustUsername
		, RegisteredDate
		, GroupId
		, Dealname
		, ScheduleId
		, ScheduleName
		--Active
		, FTD
		, IsFTD
		, TotalDeposit
		, IsTotalDeposit
		, IsTO
		, AQD
		, CPAAmount
		--Holding
		, IsHolding
		, HoldingBetTickets
		, HoldingTickets
		, HQD
		, HED
		, EstimatedCPAAmount
		--Redeposit
		, FirstDepositDate 
		, ReDepositDays 
		, ExpiredRedepositDate 
		, IsRedeposit 
		--Approval
		, StatusId
		, IsAbnormal
		, Description
		, UpdatedDate
	)
	SELECT 
		m.MemberCPA_ID
		, m.AffId
		, a.UserName
		, m.CustId
		, mem.UserName
		, mem.RegisteredDate
		, m.GroupId
		, cg.GroupName
		, cg.ScheduleId
		, s.ScheduleName
		--Active
		, m.FDM
		, IIF(m.FDM = 0, 0, 1)
		, m.TotalDeposit
		, IIF(m.TotalDeposit = 0, 0, 1)
		, IIF(m.Turnover = 0, 0, 1)
		, m.ActiveQualifiedDate
		, m.CPAAmount
		--Holding
		, IIF(m.HoldingBetTickets IS NULL, 0, 1)
		, m.HoldingBetTickets
		, cg.HoldingTickets
		, m.HoldingQualifiedDate
		, m.HoldingExpiredDate
		, CASE WHEN m.StatusId IN (2,3,5,6) THEN m.CPAAmount ELSE 0 END
		--Redeposit
		, m.FirstDepositDate
		, cg.RedepositDays
		, m.ExpiredRedepositDate
		, m.IsRedeposit
		--Approval
		, m.StatusId
		, IIF(StatusID = 4, 1, 0) AS IsAbnormal
		, m.Description
		, m.UpdatedDate
	FROM dbo.MemberCPA m WITH (NOLOCK)
		INNER JOIN dbo.MemberInfo mem WITH (NOLOCK) ON m.CustId = mem.CustId
		INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON m.AffId = a.AffId
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON m.GroupId = cg.GroupId AND cg.IsDeleted = 0
		INNER JOIN dbo.Schedule s WITH (NOLOCK) ON cg.ScheduleId = s.ScheduleId
	WHERE (ISNULL(@Username,'') = '' OR a.Username LIKE '%' + @Username + '%')
		AND (ISNULL(@Custname, '') = '' OR mem.UserName LIKE '%' + @Custname + '%')
		AND EXISTS (SELECT 1 FROM @Deals d WHERE d.GroupId = cg.GroupId)
		AND EXISTS (SELECT 1 FROM @Status s WHERE s.StatusId = m.StatusId)
		AND (
			(@Viewby = 1 AND m.ActiveQualifiedDate BETWEEN @FromDate AND @ToDate)
			OR (@Viewby = 2 AND m.HoldingQualifiedDate BETWEEN @FromDate AND @ToDate)
		)

	SELECT 
		d.MemberCPA_ID AS MemberCPAId
		, d.AffId
		, d.AffUserName
		, d.CustId
		, d.CustUserName
		, d.RegisteredDate
		, d.GroupId
		, d.DealName
		, d.ScheduleId
		, d.ScheduleName
		--Active
		, d.FTD
		, d.IsFTD
		, d.TotalDeposit
		, d.IsTotalDeposit
		, d.IsTO
		, d.AQD
		, d.CPAAmount
		--Holding
		, d.IsHolding
		, IIF(d.IsHolding = 0, NULL, d.HoldingBetTickets) AS HoldingBetTickets
		, IIF(d.IsHolding = 0, NULL, d.HoldingTickets) AS HoldingTickets
		, d.HQD
		, IIF(d.IsHolding = 0, NULL, d.HED) AS HED
		, d.EstimatedCPAAmount
		--Redeposit
		, IIF(d.ExpiredRedepositDate IS NULL, NULL, d.FirstDepositDate) AS FirstDepositDate
		, IIF(d.ExpiredRedepositDate IS NULL, NULL, d.ReDepositDays) AS ReDepositDays
		, d.ExpiredRedepositDate
		, IIF(d.ExpiredRedepositDate IS NULL, NULL, d.IsRedeposit) AS IsRedeposit
		, CASE WHEN d.StatusId = 0 THEN 'Pending'
				 WHEN d.StatusId = 1 THEN 'Ineligibled'
				  WHEN d.StatusId = 2 THEN 'Eligibled'
				   WHEN d.StatusId = 3 THEN 'Settled'
				    WHEN d.StatusId = 4 THEN 'Rejected'
					 WHEN d.StatusId = 5 THEN 'Quota Exceeded'
					  WHEN d.StatusId = 6 THEN 'Redeposit Failed'
				END AS CPAStatus
		, d.IsAbnormal
		, d.Description
	FROM #data d;

	SELECT @NRows = COUNT(MemberCPA_ID) FROM #data;
	
	-- Return sum totals for key columns
	SELECT 
		SUM(CPAAmount) AS CPAAmount,
		SUM(EstimatedCPAAmount) AS EstimatedCPAAmount
	FROM #data;
	
	DROP TABLE #data;
END;
GO
