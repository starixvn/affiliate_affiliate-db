/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_Report_PlayerCPA
	@UserName NVARCHAR(100) = ''
	,@CustName NVARCHAR(100) = ''
	,@DealName NVARCHAR(MAX) = '' --list groupids
	,@StatusId SMALLINT = -1
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
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @BaseCurrency INT
    SELECT @BaseCurrency = ISNULL(t.ExchangeId, CONVERT(INT, SValue))
    FROM dbo.SystemSettings s WITH (NOLOCK)
    LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON CONVERT(INT, SValue) = t.TpExchangeId
    WHERE SName = 'AffCurrency';

	DECLARE @Deals TABLE (GroupId INT)
	INSERT INTO @Deals (GroupId)
	SELECT CAST(f.value AS INT)
	FROM string_split(@DealName,',') f

	-- TODO: Implement Player CPA Report logic here
	-- TODO:
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
		, mem.FirstDepositAmount * ex.Rate
		, m.TotalDeposit
		, CASE WHEN mp.MemberCPA_ID IS NOT NULL THEN 1 ELSE 0 END AS IsTO
		, m.ActiveQualifiedDate
		, m.CPAAmount
		--Holding
		, m.HoldingBetTickets
		, cg.HoldingTickets
		, m.HoldingQualifiedDate
		, m.HoldingExpiredDate
		, CASE WHEN m.StatusId IN (2,3) THEN m.CPAAmount ELSE 0 END
		--Approval
		, CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END
		, m.StatusId
		, m.CPADate
		, IIF(StatusID = 4, 1, 0) AS IsAbnormal
		, m.Description
	FROM MemberCPA m WITH (NOLOCK)
	INNER JOIN MemberInfo mem WITH (NOLOCK) ON m.CustId = mem.CustId
	LEFT JOIN dbo.TpExchange te WITH (NOLOCK) ON mem.Currency = te.TpExchangeId
	CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(mem.FirstDepositDate, ISNULL(te.ExchangeId, mem.Currency), @BaseCurrency) ex
	INNER JOIN AffInfo a WITH (NOLOCK) ON m.AffId = a.AffId
	INNER JOIN CommGroup cg WITH (NOLOCK) ON m.GroupId = cg.GroupId AND cg.IsDeleted = 0
	INNER JOIN Schedule s WITH (NOLOCK) ON cg.ScheduleId = s.ScheduleId
	OUTER APPLY (SELECT DISTINCT a.MemberCPA_ID FROM MemberCPAProduct a WITH (NOLOCK) WHERE m.MemberCPA_ID = a.MemberCPA_ID) mp  
	WHERE (@Username = '' OR a.Username LIKE '%' + @Username + '%')
		AND (@Custname = '' OR mem.UserName LIKE '%' + @Custname + '%')
		AND EXISTS (SELECT 1 FROM @Deals d WHERE d.GroupId = cg.GroupId)
		AND (@StatusId = -1 OR m.StatusId = @StatusId)
		AND (
			(@Viewby = 1 AND m.ActiveQualifiedDate BETWEEN @FromDate AND @ToDate)
			OR (@Viewby = 2 AND m.HoldingQualifiedDate BETWEEN @FromDate AND @ToDate)
			OR (@Viewby = 3 AND m.CPADate BETWEEN @FromDate AND @ToDate)
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
		, d.FTD
		, d.TotalDeposit
		, d.IsTO
		, d.AQD
		, d.CPAAmount
		, d.HoldingBetTickets
		, d.HoldingTickets
		, d.HQD
		, d.HED
		, d.EstimatedCPAAmount
		, d.ApprovedCPAAmount
		, CASE WHEN d.StatusId = 0 THEN 'Pending'
				 WHEN d.StatusId = 1 THEN 'Ineligibled'
				  WHEN d.StatusId = 2 THEN 'Eligibled'
				   WHEN d.StatusId = 3 THEN 'Approved'
				    WHEN d.StatusId = 4 THEN 'Rejected'
					 WHEN d.StatusId = 5 THEN 'Quota Exceeded'
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
GO
