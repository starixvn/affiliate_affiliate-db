/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Report_PaymentCPA]
    @AffId INT,
    @Status VARCHAR(MAX) = '',
    @Viewby TINYINT = 1,
    @FromDate DATETIME = '',
    @ToDate DATETIME = '',
    @IsExportExcel BIT = 0,
    @PageIndex INT = 1,
    @PageSize INT = 20,
    @NRows INT = 0 OUTPUT
AS

/*
    Created: 20251030@Lewis
    DB: DBAFF12B-Affiliate_12B  
    Task: User - CPA Report - Payment CPA Report

    Parameter's Explanation:
        - @Viewby: 1 Schedule End Date
                   2 Auto Approved Date  
                   3 Adjustment Date

    Revisions:
        - 20251030@Lewis: Initialize SP [RedmineID: #241619]
*/

BEGIN
    SET NOCOUNT ON

        -- Input validation

        DECLARE @Statuses TABLE (Status VARCHAR(50))
        INSERT INTO @Statuses (Status)
        SELECT f.value
        FROM string_split(@Status,',') f

        DECLARE @TimeZone SMALLINT
        SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
        FROM dbo.SystemSettings WITH (NOLOCK) 
        WHERE SName = 'TimeZone';

        DECLARE @CurrentDate DATETIME = CAST(DATEADD(HOUR, @TimeZone, GETUTCDATE()) AS DATE)

        CREATE TABLE #data (
            ID INT,
            Rid INT,
            StartSchedule DATE,
            EndSchedule DATE,
            AffId INT,
            GroupId INT,
            Dealname VARCHAR(200),
            PaymentFrequency VARCHAR(200),
            RedepositDays INT,
            RedepositRate DECIMAL(9,8),
            Status VARCHAR(50),
            ExpiredRedepositDate DATETIME,
            TotalEligiblePlayers INT,
            TotalRedepositPlayers INT,
            TotalRequiredRedepositPlayers INT,
            EstimateAmount MONEY,
            ApprovedAmount MONEY,
            ApprovedDate DATE,
            ManuallyApprovedAmount MONEY,
            ManuallyApprovedDate DATE,
            Description NVARCHAR(300),
            AdjustedAmount MONEY,
            FinalCPAAmount MONEY,
            IsAdjustmentEnabled BIT
        )

        INSERT INTO #data(
            ID,
            Rid,
            StartSchedule,
            EndSchedule,
            AffId,
            GroupId,
            Dealname,
            PaymentFrequency,
            RedepositDays,
            RedepositRate,
            Status,
            ExpiredRedepositDate,
            TotalEligiblePlayers,
            TotalRedepositPlayers,
            TotalRequiredRedepositPlayers,
            EstimateAmount,
            ApprovedAmount,
            ApprovedDate,
            ManuallyApprovedAmount,
            ManuallyApprovedDate,
            Description,
            AdjustedAmount,
            FinalCPAAmount,
            IsAdjustmentEnabled
        )
        SELECT 
            r.ID,
            ROW_NUMBER() OVER(ORDER BY r.EndSchedule ASC) AS Rid,
            r.StartSchedule,
            r.EndSchedule,
            r.AffId,
            r.GroupId,
            cg.GroupName,
            s.ScheduleName AS PaymentFrequency,
            cg.RedepositDays,
            cg.RedepositRate,
            r.Status,
            r.ExpiredRedepositDate,
            r.TotalEligiblePlayers,
            r.TotalRedepositPlayers,
            FLOOR(r.TotalEligiblePlayers * cg.RedepositRate) AS TotalRequiredRedepositPlayers,
            r.EstimateAmount,
            ISNULL(r.ApprovedAmount, 0),
            r.ApprovedDate,
            ISNULL(r.AdjustedAmount, 0),
            r.AdjustedDate,
            r.Description,
            IIF(r.AdjustedDate IS NULL, 0, ISNULL(r.AdjustedAmount,0) - ISNULL(r.ApprovedAmount,0)),
            COALESCE(r.AdjustedAmount, r.ApprovedAmount, 0) AS FinalCPAAmount,
            IIF(DATEADD(DAY, -60, @CurrentDate) > (IIF(r.EndSchedule >= r.ExpiredRedepositDate, r.EndSchedule, r.ExpiredRedepositDate)), 0, 1) AS IsAdjustmentEnabled
        FROM dbo.rptAffiliateCPA r WITH (NOLOCK)
            INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON r.GroupId = cg.GroupId AND cg.IsDeleted = 0
            INNER JOIN dbo.Schedule s WITH (NOLOCK) ON cg.ScheduleId = s.ScheduleId
        WHERE r.AffId = @AffId
            AND EXISTS (SELECT 1 FROM @Statuses st WHERE st.Status = r.Status)
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
            d.Rid AS RowNum,
            d.GroupId,
            --Payment Schedule
            d.StartSchedule AS StartDate,
            d.EndSchedule AS EndDate,
            d.RedepositDays AS RecheckDays,
            d.ExpiredRedepositDate,
            --Redeposit Statistics  
            d.TotalEligiblePlayers AS EligiblePlayers,
            d.RedepositRate AS RedepositPercentage,
            IIF(d.Status = 'Empty' , NULL, CONCAT(d.TotalRedepositPlayers, '/', d.TotalRequiredRedepositPlayers)) AS NoOfPlayerRedeposit,
            --Estimated CPA Amount
            d.EstimateAmount AS EstimatedCPAAmount,
            --Status
            d.Status,
            CASE WHEN d.Status = 'Monitoring' THEN 1
                 WHEN d.Status = 'Not Qualified' THEN 2
                 WHEN d.Status = 'Qualified' THEN 3
                 WHEN d.Status = 'Empty' THEN 4
            END AS StatusId,
            --Automatically Approved
            d.ApprovedAmount AS AutomaticallyApprovedAmount,
            d.ApprovedDate AS AutomaticallyApprovedDate,
            --Manually Approved
            d.ManuallyApprovedAmount AS ManuallyApprovedAmount,
            d.ManuallyApprovedDate AS ManuallyApprovedDate,
            d.Description AS AdjustmentDescription,
            --Final
            d.AdjustedAmount,
            d.FinalCPAAmount
        FROM #data d
        WHERE d.Rid BETWEEN @RowStart AND @RowEnd
        ORDER BY d.EndSchedule ASC;

        -- Summary totals
        SELECT 
            SUM(TotalEligiblePlayers) AS EligiblePlayers,
            SUM(EstimateAmount) AS EstimatedCPAAmount,
            SUM(ApprovedAmount) AS AutomaticallyApprovedAmount,
            SUM(ManuallyApprovedAmount) AS ManuallyApprovedAmount,
            SUM(AdjustedAmount) AS AdjustedAmount,
            SUM(FinalCPAAmount) AS FinalCPAAmount
        FROM #data;

        DROP TABLE #data;

END
GO