/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_Aff_CPAPaymentSchedule
    @CPADate DATE,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created:      20250703@Lewis
    Task:         Step 5 - CPA Payment Schedule Aff
    DB:           DBAFF12B-Affiliate_12B
    
    Purpose:      Calculate and update CPA payment schedules for affiliates
                  - Process new qualified members
                  - Update existing monitoring records
                  - Handle AffId GroupId changes
    
    Revisions:
        - 20250930@Lewis: Initial [RedmineID: #235601]
*/
BEGIN
    SET NOCOUNT ON;
    
    -- =============================================
    -- INITIALIZATION & VALIDATION
    -- =============================================
    
    -- Input validation
    IF @CPADate IS NULL 
    BEGIN
        SET @ErrCode = 100;
        SET @ErrMsg = 'Parameter @CPADate is required and cannot be NULL';
        RETURN;
    END

    -- Constants and variables
    DECLARE @ToDate DATETIME = '9999-12-31',
            @TimeZone SMALLINT;
    
    -- Get timezone setting
    SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
    FROM dbo.SystemSettings WITH (NOLOCK) 
    WHERE SName = 'TimeZone';
    
    -- =============================================
    -- TEMPORARY TABLES INITIALIZATION
    -- =============================================

    -- Current eligible groups for new processing
    CREATE TABLE #EligibleGroupsWithAff (
        GroupId INT,
        AffId INT,
        ScheduleId INT,
        FromSchedule DATE,
        ToSchedule DATE,
        RedepositDays INT,
        RedepositRate DECIMAL(9,8)
    );

    -- New qualified members for current schedule
    CREATE TABLE #QualifiedMembers (
        MemberCPA_ID INT,
        AffId INT,
        GroupId INT,
        CustId INT,
        HoldingQualifiedDate DATETIME,
        CPAAmount MONEY,
        StatusId INT,
        IsRedeposit BIT,
        ExpiredRedepositDate DATETIME
    );

    -- New CPA payment schedule results
    CREATE TABLE #NewCPASchedule (
        AffId INT,
        GroupId INT,
        FromSchedule DATE,
        ToSchedule DATE,
        Status VARCHAR(50),
        ExpiredRedepositDate DATETIME,
        TotalEligiblePlayers INT,
        RequiredRedepositPlayers INT,
        TotalRedepositPlayers INT,
        EstimateAmount MONEY
    );

    -- Old monitoring data to be updated
    CREATE TABLE #OldMonitoringGroups (
        ID INT,
        AffId INT,
        GroupId INT,
        FromSchedule DATE,
        ToSchedule DATE,
        RedepositRate DECIMAL(9,8)
    );

    -- Updated monitoring schedule results
    CREATE TABLE #UpdatedMonitoringSchedule (
        ID INT,
        AffId INT,
        GroupId INT,
        FromSchedule DATE,
        ToSchedule DATE,
        Status VARCHAR(50),
        ExpiredRedepositDate DATETIME,
        TotalEligiblePlayers INT,
        RequiredRedepositPlayers INT,
        TotalRedepositPlayers INT,
        EstimateAmount MONEY
    );

    -- =============================================
    -- DATA LOADING
    -- =============================================
    
    -- Load eligible groups with affiliates for new CPA processing
    INSERT INTO #EligibleGroupsWithAff (GroupId, AffId, ScheduleId, FromSchedule, ToSchedule, RedepositDays, RedepositRate)
    SELECT s.GroupId,
           agh.AffId,
           s.ScheduleId,
           DATEADD(DAY, -sc.IntervalValue + 1, @CPADate) AS FromSchedule,
           @CPADate AS ToSchedule,
           c.RedepositDays,
           c.RedepositRate
    FROM dbo.DealBillingSchedule s WITH (NOLOCK)
    INNER JOIN dbo.CPAGroupSetting c WITH (NOLOCK) 
        ON s.GroupId = c.GroupId 
       AND c.ToDate = @ToDate
    INNER JOIN dbo.Schedule sc WITH (NOLOCK)
        ON sc.ScheduleId = s.ScheduleId
    INNER JOIN dbo.AffGroupHistory agh WITH (NOLOCK)
        ON s.GroupId = agh.GroupId
       AND agh.ToDate = @ToDate
    WHERE s.NextBillingDate = @CPADate
      AND NOT EXISTS (
          SELECT 1 
          FROM dbo.CommGroup cg WITH (NOLOCK) 
          WHERE cg.GroupId = c.GroupId 
            AND cg.IsDeleted = 1
      );
    
    -- Load qualified members for new processing
    INSERT INTO #QualifiedMembers (MemberCPA_ID, AffId, GroupId, CustId, HoldingQualifiedDate, CPAAmount, StatusId, ExpiredRedepositDate, IsRedeposit)
    SELECT m.MemberCPA_ID,
           m.AffId, 
           m.GroupId, 
           m.CustId, 
           m.HoldingQualifiedDate,
           m.CPAAmount, 
           m.StatusId,
           m.ExpiredRedepositDate, --NULL => no setting Redeposit Condition
           m.IsRedeposit
    FROM dbo.MemberCPA m WITH (NOLOCK)
    INNER JOIN #EligibleGroupsWithAff egwa ON m.GroupId = egwa.GroupId AND m.AffId = egwa.AffId  -- Must match both to get correct member attribution
    WHERE m.StatusId = 2
        AND m.HoldingQualifiedDate BETWEEN egwa.FromSchedule AND egwa.ToSchedule;
    
    -- Load old monitoring data that needs to be updated
    INSERT INTO #OldMonitoringGroups (ID, AffId, GroupId, FromSchedule, ToSchedule, RedepositRate)
    SELECT r.ID, 
           r.AffId, 
           r.GroupId, 
           r.StartSchedule, 
           r.EndSchedule, 
           c.RedepositRate
    FROM dbo.rptAffiliateCPA r WITH (NOLOCK)
    INNER JOIN dbo.CPAGroupSetting c WITH (NOLOCK) 
        ON r.GroupId = c.GroupId 
       AND c.ToDate = @ToDate
    WHERE r.Status = 'Monitoring'
        AND r.EndSchedule < @CPADate  -- Only old monitoring data
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.CommGroup cg WITH (NOLOCK) 
            WHERE cg.GroupId = c.GroupId 
              AND cg.IsDeleted = 1
        );
        
    -- =============================================
    -- CPA SCHEDULE CALCULATIONS
    -- =============================================

    -- Calculate updated monitoring schedule for existing records
    WITH cte_OldMonitoringWithMembers AS (
        -- Get all old monitoring records with their member data (if any)
        SELECT omg.ID,
               omg.AffId,
               omg.GroupId,
               omg.FromSchedule,
               omg.ToSchedule,
               m.CustId,
               m.CPAAmount,
               m.ExpiredRedepositDate,
               m.IsRedeposit,
               omg.RedepositRate
        FROM #OldMonitoringGroups omg
        LEFT JOIN dbo.MemberCPA m WITH (NOLOCK)
            ON m.AffId = omg.AffId 
           AND m.GroupId = omg.GroupId  -- Must match both AffId and GroupId
           AND m.StatusId = 2
           AND m.HoldingQualifiedDate BETWEEN omg.FromSchedule AND omg.ToSchedule
    ),
    cte_OldMonitoringAggregated AS (
        -- Aggregate metrics per monitoring record (handle zero members case)
        SELECT omwm.ID,
               omwm.AffId,
               omwm.GroupId,
               omwm.FromSchedule,
               omwm.ToSchedule,
               MAX(omwm.ExpiredRedepositDate) AS ExpiredRedepositDate,
               COUNT(omwm.CustId) AS TotalEligiblePlayers,  -- Will be 0 for records with no members
               FLOOR(COUNT(omwm.CustId) * omwm.RedepositRate) AS RequiredRedepositPlayers,
               SUM(CASE WHEN omwm.IsRedeposit = 1 THEN 1 ELSE 0 END) AS TotalRedepositPlayers,
               SUM(ISNULL(omwm.CPAAmount, 0)) AS EstimateAmount
        FROM cte_OldMonitoringWithMembers omwm
        GROUP BY omwm.ID, omwm.AffId, omwm.GroupId, omwm.FromSchedule, omwm.ToSchedule, omwm.RedepositRate
    )
    INSERT INTO #UpdatedMonitoringSchedule (ID, AffId, GroupId, FromSchedule, ToSchedule, Status, ExpiredRedepositDate, TotalEligiblePlayers, RequiredRedepositPlayers, TotalRedepositPlayers, EstimateAmount)
    SELECT oma.ID,
           oma.AffId,
           oma.GroupId,
           oma.FromSchedule,
           oma.ToSchedule,
           CASE 
			   WHEN oma.TotalEligiblePlayers = 0 -- No qualified members anymore
					THEN 'Empty'

			   WHEN oma.ExpiredRedepositDate IS NULL -- no setting Redeposit Condition
					THEN 'Qualified'

			   WHEN oma.TotalRedepositPlayers < oma.RequiredRedepositPlayers 
					AND DATEADD(DAY, 1, @CPADate) <= oma.ExpiredRedepositDate
					THEN 'Monitoring'

			   WHEN oma.TotalRedepositPlayers >= oma.RequiredRedepositPlayers 
					AND DATEADD(DAY, 1, @CPADate) <= oma.ExpiredRedepositDate
					THEN 'Qualified'

			   ELSE 'Not Qualified'
			END AS Status,
           oma.ExpiredRedepositDate,
           oma.TotalEligiblePlayers,
           oma.RequiredRedepositPlayers,
           oma.TotalRedepositPlayers,
           oma.EstimateAmount
    FROM cte_OldMonitoringAggregated oma;

    -- Calculate new CPA schedule for current period (include groups with no members)
    WITH cte_AllEligibleGroupsWithMembers AS (
        -- Get all eligible groups with their member data (if any)
        SELECT egwa.AffId,
               egwa.GroupId,
               qm.CustId,
               egwa.FromSchedule,
               egwa.ToSchedule,
               qm.CPAAmount,
               qm.ExpiredRedepositDate,
               qm.IsRedeposit,
               egwa.RedepositRate
        FROM #EligibleGroupsWithAff egwa
        LEFT JOIN #QualifiedMembers qm 
            ON egwa.GroupId = qm.GroupId 
           AND egwa.AffId = qm.AffId  -- Must match both to get correct member attribution
    ),
    cte_NewScheduleAggregated AS (
        -- Aggregate metrics per affiliate and group (handle zero members case)
        SELECT aegwm.AffId,
               aegwm.GroupId,
               aegwm.FromSchedule,
               aegwm.ToSchedule,
               MAX(aegwm.ExpiredRedepositDate) AS ExpiredRedepositDate,
               COUNT(aegwm.CustId) AS TotalEligiblePlayers,  -- Will be 0 for groups with no members
               FLOOR(COUNT(aegwm.CustId) * aegwm.RedepositRate) AS RequiredRedepositPlayers,
               SUM(CASE WHEN aegwm.IsRedeposit = 1 THEN 1 ELSE 0 END) AS TotalRedepositPlayers,
               SUM(ISNULL(aegwm.CPAAmount, 0)) AS EstimateAmount
        FROM cte_AllEligibleGroupsWithMembers aegwm
        GROUP BY aegwm.AffId, aegwm.GroupId, aegwm.FromSchedule, aegwm.ToSchedule, aegwm.RedepositRate
    )
    INSERT INTO #NewCPASchedule (AffId, GroupId, FromSchedule, ToSchedule, Status, ExpiredRedepositDate, TotalEligiblePlayers, RequiredRedepositPlayers, TotalRedepositPlayers, EstimateAmount)
    SELECT nsa.AffId,
           nsa.GroupId,
           nsa.FromSchedule,
           nsa.ToSchedule,
           CASE 
			   WHEN nsa.TotalEligiblePlayers = 0 -- No qualified members
					THEN 'Empty'

			   WHEN nsa.ExpiredRedepositDate IS NULL -- no setting Redeposit Condition
					THEN 'Qualified'

			   WHEN nsa.TotalRedepositPlayers < nsa.RequiredRedepositPlayers 
					AND DATEADD(DAY, 1, @CPADate) <= IIF(nsa.ToSchedule >= nsa.ExpiredRedepositDate, nsa.ToSchedule, nsa.ExpiredRedepositDate)
					THEN 'Monitoring'

			   WHEN nsa.TotalRedepositPlayers >= nsa.RequiredRedepositPlayers 
					THEN 'Qualified'

			   ELSE 'Not Qualified'
			END AS Status,
           nsa.ExpiredRedepositDate,
           nsa.TotalEligiblePlayers,
           nsa.RequiredRedepositPlayers,
           nsa.TotalRedepositPlayers,
           nsa.EstimateAmount
    FROM cte_NewScheduleAggregated nsa;

    -- =============================================
    -- DATABASE UPDATES
    -- =============================================
 
    -- Update existing monitoring records with recalculated metrics
    UPDATE r
    SET r.Status = ums.Status,
        r.ExpiredRedepositDate = ums.ExpiredRedepositDate,
        r.TotalEligiblePlayers = ums.TotalEligiblePlayers,
        r.TotalRedepositPlayers = ums.TotalRedepositPlayers,
        r.EstimateAmount = ums.EstimateAmount,
        r.IsProcessed = IIF(ums.Status = 'Empty', 1, 0),  -- Mark as processed if no qualified members
        r.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
    FROM dbo.rptAffiliateCPA r WITH (UPDLOCK, ROWLOCK)
    INNER JOIN #UpdatedMonitoringSchedule ums ON r.ID = ums.ID;
    
    -- Insert new CPA schedule records
    INSERT INTO dbo.rptAffiliateCPA (
		StartSchedule,
		EndSchedule,
		AffId,
		GroupId,
		Status,
		ExpiredRedepositDate,
		TotalEligiblePlayers,
		TotalRedepositPlayers,
		EstimateAmount,
        IsProcessed,
		UpdatedDate
	)
	SELECT ncs.FromSchedule,
		ncs.ToSchedule,
		ncs.AffId,
		ncs.GroupId,
		ncs.Status,
		ncs.ExpiredRedepositDate,
		ncs.TotalEligiblePlayers,
		ncs.TotalRedepositPlayers,
		ncs.EstimateAmount,
        IIF(ncs.Status = 'Empty', 1, 0) AS IsProcessed,  -- Mark as processed if no qualified members
		DATEADD(HOUR, @TimeZone, GETUTCDATE())
	FROM #NewCPASchedule ncs
    
    -- Success
    SET @ErrCode = 0;
    SET @ErrMsg = 'CPA Payment Schedule processed successfully';

    -- =============================================
    -- CLEANUP
    -- =============================================

    DROP TABLE IF EXISTS #EligibleGroupsWithAff;
    DROP TABLE IF EXISTS #QualifiedMembers;
    DROP TABLE IF EXISTS #NewCPASchedule;
    DROP TABLE IF EXISTS #OldMonitoringGroups;
    DROP TABLE IF EXISTS #UpdatedMonitoringSchedule;

END;
GO