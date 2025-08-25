/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Report_PlayerCPA]
	@AffId		INT
	,@StatusId	SMALLINT	= -1
	,@Viewby	TINYINT		= 1
	,@FromDate	DATETIME	= ''
	,@ToDate	DATETIME	= ''
	,@NRows		INT			= 0	 OUTPUT
/*
	Created: 20250822@Danny
	Task:         Player CPA Report
	DB:           DBAFF12B-Affiliate_12B
	Revisions:
		- 20250822@Danny: Initial [RedmineID: #228530]
*/
AS
BEGIN
	-- TODO: Implement Player CPA Report logic here
	-- TODO:
	CREATE TABLE #data (
		MemberCPA_ID INT
		, CustId INT
		, CustUsername VARCHAR(100)
		, RegisteredDate DATETIME
		--Active
		, FTD MONEY
		, TotalDeposit MONEY
		, IsTO BIT
		, AQD DATETIME
		, CPAAmount MONEY
		--Holding
		, HoldingBetTickets SMALLINT
		, HoldingTickets SMALLINT
		, HQD DATETIME
		, HED DATETIME
		, EstimatedCPAAmount MONEY
		--Approval
		, ApprovedCPAAmount MONEY
		, StatusId SMALLINT
		, CPADate DATETIME
		, IsAbnormal BIT
		, Description VARCHAR(300)
	)
	INSERT INTO #data(
		MemberCPA_ID
		, CustId
		, CustUsername
		, RegisteredDate
		--Active
		, FTD
		, TotalDeposit
		, IsTO
		, AQD
		, CPAAmount
		--Holding
		, HoldingBetTickets
		, HoldingTickets
		, HQD
		, HED
		, EstimatedCPAAmount
		--Approval
		, ApprovedCPAAmount
		, StatusId
		, CPADate
		, IsAbnormal
		, Description
	)
	SELECT 
		m.MemberCPA_ID
		, m.CustId
		, mem.UserName
		, mem.RegisteredDate
		--Active
		, mem.FirstDepositAmount
		, m.TotalDeposit
		, CASE WHEN mp.MemberCPA_ID IS NOT NULL THEN 1 ELSE 0 END AS IsTO
		, m.ActiveQualifiedDate
		, m.CPAAmount
		--Holding
		, m.HoldingBetTickets
		, cg.HoldingTickets
		, m.HoldingQualifiedDate
		, DATEADD(DAY, -1 + cg.HoldingDays, m.HoldingQualifiedDate)
		, CASE WHEN m.StatusId = 2 THEN m.CPAAmount ELSE 0 END
		--Approval
		, CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END
		, m.StatusId
		, m.CPADate
		, IIF(StatusID = 4, 1, 0) AS IsAbnormal
		, m.Description
	FROM MemberCPA m WITH (NOLOCK)
	INNER JOIN MemberInfo mem WITH (NOLOCK) ON m.CustId = mem.CustId
	INNER JOIN CommGroup cg WITH (NOLOCK) ON m.GroupId = cg.GroupId AND cg.IsDeleted = 0
	INNER JOIN Schedule s WITH (NOLOCK) ON cg.ScheduleId = s.ScheduleId
	OUTER APPLY (SELECT DISTINCT a.MemberCPA_ID FROM MemberCPAProduct a WITH (NOLOCK) WHERE m.MemberCPA_ID = a.MemberCPA_ID) mp  
	WHERE m.AffId = @AffId
		AND (@StatusId = -1 OR m.StatusId = @StatusId)
		AND (
			(@Viewby = 1 AND m.ActiveQualifiedDate BETWEEN @FromDate AND @ToDate)
			OR (@Viewby = 2 AND m.HoldingQualifiedDate BETWEEN @FromDate AND @ToDate)
			OR (@Viewby = 3 AND m.CPADate BETWEEN @FromDate AND @ToDate)
		)

	SELECT 
		d.MemberCPA_ID AS MemberCPAId
		, d.CustId
		, d.CustUserName
		, d.RegisteredDate
		-- Active Period
		, d.FTD
		, d.TotalDeposit
		, d.AQD
		, d.CPAAmount
		-- Holding Period
		, d.HoldingBetTickets
		, d.HoldingTickets
		, d.HQD
		, d.HED
		, d.EstimatedCPAAmount
		-- Approval Period
		, d.ApprovedCPAAmount
		, CASE WHEN d.StatusId = 0 THEN 'Pending'
				 WHEN d.StatusId = 1 THEN 'Ineligibled'
				  WHEN d.StatusId = 2 THEN 'Eligibled'
				   WHEN d.StatusId = 3 THEN 'Approved'
				    WHEN d.StatusId = 4 THEN 'Rejected'
					 WHEN d.StatusId = 5 THEN 'Exceed'
				END AS CPAStatus
		, d.CPADate
		, d.IsAbnormal
		, d.Description
	FROM #data d;

	SELECT @NRows = COUNT(*) FROM #data;
	
	-- Return sum totals for key columns
	SELECT 
		SUM(FTD) AS FTD,
		SUM(TotalDeposit) AS TotalDeposit,
		SUM(CPAAmount) AS CPAAmount,
		SUM(EstimatedCPAAmount) AS EstimatedCPAAmount,
		SUM(ApprovedCPAAmount) AS ApprovedCPAAmount
	FROM #data;
	
	DROP TABLE #data;
END;
