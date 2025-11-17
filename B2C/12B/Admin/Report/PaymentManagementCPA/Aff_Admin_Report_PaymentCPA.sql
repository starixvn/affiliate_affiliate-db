/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_Report_PaymentCPA
	@UserName NVARCHAR(100) = ''
	,@DealIds NVARCHAR(MAX) = '' --list groupids
	,@Status VARCHAR(MAX) = ''
	,@Viewby TINYINT = 1
	,@FromDate DATETIME = ''
	,@ToDate DATETIME = ''
	,@IsExportExcel BIT = 0
	,@PageIndex INT = 1
	,@PageSize INT = 20
	,@NRows INT = 0 OUTPUT
/*
	Created:      20251003@Lewis
	Task:         Payment CPA Report
	DB:           DBAFF12B-Affiliate_12B
	Revisions:
		- 20250721@Lewis: Initial [RedmineID: #240525]
		- 20251112@Lewis: Status Empty => NOredeposit is NULL [RedmineID: #236665]

	Parameter's Explanation:
		- @Viewby: 1 EndSchedule
				   2 Approved Date
				   3 Adjusted Date
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @Deals TABLE (GroupId INT)
	INSERT INTO @Deals (GroupId)
	SELECT CAST(f.value AS INT)
	FROM string_split(@DealIds,',') f

	DECLARE @Statuses TABLE (Status VARCHAR(50))
	INSERT INTO @Statuses (Status)
	SELECT f.value
	FROM string_split(@Status,',') f

	DECLARE @TimeZone SMALLINT

    SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
    FROM dbo.SystemSettings WITH (NOLOCK) 
    WHERE SName = 'TimeZone';

	DECLARE @CurrentDate DATETIME = CAST(DATEADD(HOUR, @TimeZone, GETUTCDATE()) AS DATE)

	-- TODO: Implement Payment CPA Report logic here
	CREATE TABLE #data (
		ID int
		,Rid int
		,StartSchedule date
		,EndSchedule date
		,AffId int
		,AffUserName varchar(100)
		,GroupId int
		,Dealname varchar(200)
		,ScheduleId int
		,PaymentFrequency varchar(200)
		,RedepositDays int
		,RedepositRate DECIMAL(9,8)
		,Status	varchar(50)
		,ExpiredRedepositDate datetime
		,TotalEligiblePlayers int
		,TotalRedepositPlayers int
		,TotalRequiredRedepositPlayers int
		,EstimateAmount money
		,ApprovedAmount money
		,ApprovedDate date
		,ManuallyApprovedAmount money
		,ManuallyApprovedDate date
		,Description nvarchar(300)
		,ManuallyApprovedBy int
		,AdjustedAmount money
		,FinalCPAAmount money
	)
	INSERT INTO #data(
		ID
		,Rid
		,StartSchedule
		,EndSchedule
		,AffId
		,AffUserName
		,GroupId
		,Dealname
		,ScheduleId
		,PaymentFrequency
		,RedepositDays
		,RedepositRate
		,Status
		,ExpiredRedepositDate
		,TotalEligiblePlayers
		,TotalRedepositPlayers
		,TotalRequiredRedepositPlayers
		,EstimateAmount
		,ApprovedAmount
		,ApprovedDate
		,ManuallyApprovedAmount
		,ManuallyApprovedDate
		,Description
		,ManuallyApprovedBy
		,AdjustedAmount
		,FinalCPAAmount
	)
	SELECT 
		r.ID
		, ROW_NUMBER() OVER(ORDER BY r.AffId ASC, r.GroupId ASC) AS Rid
		, r.StartSchedule
		, r.EndSchedule
		, r.AffId
		, a.Username AS AffUserName
		, r.GroupId
		, cg.GroupName
		, s.ScheduleId
		, s.ScheduleName AS PaymentFrequency
		, cg.RedepositDays
		, cg.RedepositRate
		, r.Status
		, r.ExpiredRedepositDate
		, r.TotalEligiblePlayers
		, r.TotalRedepositPlayers
		, FLOOR(r.TotalEligiblePlayers * cg.RedepositRate) AS TotalRequiredRedepositPlayers
		, r.EstimateAmount
		, ISNULL(r.ApprovedAmount,0)
		, IIF(r.Status = 'Empty', NULL, r.ApprovedDate)
		, ISNULL(r.AdjustedAmount,0)
		, r.AdjustedDate
		, r.Description
		, r.AdjustedBy
		, IIF(r.AdjustedDate IS NULL, 0, ISNULL(r.AdjustedAmount,0) - ISNULL(r.ApprovedAmount,0))
		, COALESCE(r.AdjustedAmount, r.ApprovedAmount, 0) AS FinalCPAAmount
	FROM dbo.rptAffiliateCPA r WITH (NOLOCK)
	INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON r.AffId = a.AffId
	INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON r.GroupId = cg.GroupId AND cg.IsDeleted = 0
	INNER JOIN dbo.Schedule s WITH (NOLOCK) ON cg.ScheduleId = s.ScheduleId
	WHERE (a.UserName LIKE '%' + @UserName + '%' OR @UserName = '')
	  AND EXISTS (SELECT TOP 1 1 FROM @Deals d WHERE d.GroupId = r.GroupId)
	  AND EXISTS (SELECT TOP 1 1 FROM @Statuses s WHERE s.Status = r.Status)
	  AND (
	  		(@Viewby = 1 AND r.EndSchedule BETWEEN @FromDate AND @ToDate)
			OR (@Viewby = 2 AND r.ApprovedDate BETWEEN @FromDate AND @ToDate)
			OR (@Viewby = 3 AND r.AdjustedDate BETWEEN @FromDate AND @ToDate)
	  	)

	-- Paging logic
	SELECT @NRows = COUNT(DISTINCT Rid) FROM #data;

    DECLARE @RowStart INT, @RowEnd INT;

    IF @IsExportExcel = 0
    BEGIN
        SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1,
               @RowEnd = @RowStart + @PageSize - 1;
    END
    ELSE
    BEGIN
        SELECT @RowStart = 1,
               @RowEnd = @NRows;
    END
	
	-- Return paged results
	SELECT 
		d.ID AS PaymentID
		,d.Rid
		,d.StartSchedule
		,d.EndSchedule
		,d.AffId
		,d.AffUserName
		,d.GroupId
		,d.Dealname
		,d.ScheduleId
		,d.PaymentFrequency
		,d.RedepositDays
		,d.RedepositRate
		,d.Status
		,CASE WHEN d.Status = 'Monitoring' THEN 1
			 WHEN d.Status = 'Not Qualified' THEN 2
			 WHEN d.Status = 'Qualified' THEN 3
			 WHEN d.Status = 'Empty' THEN 4
		END AS StatusId
		,d.ExpiredRedepositDate
		,d.TotalEligiblePlayers
		,IIF(d.Status = 'Empty', NULL, CONCAT(d.TotalRedepositPlayers,'/',d.TotalRequiredRedepositPlayers)) AS NoOfRedepositPlayers
		,d.EstimateAmount
		,d.ApprovedAmount
		,d.ApprovedDate
		,d.ManuallyApprovedAmount
		,d.ManuallyApprovedDate
		,d.Description
		,d.ManuallyApprovedBy
		,d.AdjustedAmount
		,d.FinalCPAAmount
		,IIF(d.ManuallyApprovedDate IS NULL
				, IIF(DATEADD(DAY, -60, @CurrentDate) > (IIF(ISNULL(d.ApprovedDate,d.EndSchedule) >= d.ExpiredRedepositDate, ISNULL(d.ApprovedDate,d.EndSchedule), d.ExpiredRedepositDate)), 0, 1)
				, 0) AS IsEnabled
	FROM #data d
	WHERE d.Rid BETWEEN @RowStart AND @RowEnd;

	-- Return sum totals for key columns
	SELECT 
		SUM(TotalEligiblePlayers) AS TotalEligiblePlayers,
		SUM(EstimateAmount) AS EstimateAmount,
		SUM(ApprovedAmount) AS ApprovedAmount,
		SUM(ManuallyApprovedAmount) AS ManuallyApprovedAmount,
		SUM(AdjustedAmount) AS AdjustedAmount,
		SUM(FinalCPAAmount) AS FinalCPAAmount
	FROM #data;
	
	DROP TABLE #data;
END;
GO
