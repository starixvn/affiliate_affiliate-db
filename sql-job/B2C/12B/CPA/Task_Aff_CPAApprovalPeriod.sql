/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_Aff_CPAApprovalPeriod
    @CPADate DATE
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created:      20250716@Lewis
    Task:         CPA Approval Processing with 3-Level Sub-Commission
    DB:           DBAFF12B-Affiliate_12B
    
    Note:         Billing schedule updates are handled by separate SP: Task_Aff_UpdateCPABillingSchedule
    
    Revisions:
        - 20250716@Lewis: Initial implementation [RedmineID: #283530]
		- 20250930@Lewis: Enhance Auto Approved [RedmineID: #235601]
*/
BEGIN
	SET NOCOUNT ON;
    
    BEGIN TRY
        -- =============================================
        -- SECTION 1: INPUT VALIDATION & CONSTANTS
        -- =============================================
        
        -- Validate required parameters
        IF @CPADate IS NULL 
        BEGIN
            SET @ErrCode = 100;
            SET @ErrMsg = 'Parameter @CPADate is required and cannot be NULL';
            RETURN;
        END

        -- System constants and variables
        DECLARE @Todate DATETIME = '9999-12-31',
                @AffCurrency INT,
                @AffRate FLOAT,
                @CreatorId INT = 148,
                @MainTransType SMALLINT = 206,
                @SubTransType SMALLINT = 207,
                @MaxLevels INT = 3,
                @TimeZone SMALLINT,
                @TransDate DATETIME = GETDATE(),
                @CPADatePlus1 DATETIME = DATEADD(DAY, 1, @CPADate);

        -- Load system settings
        SELECT @AffCurrency = CONVERT(INT, SValue) 
        FROM dbo.SystemSettings WITH (NOLOCK) 
        WHERE SName = 'AffCurrency';
        
        SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
        FROM dbo.SystemSettings WITH (NOLOCK) 
        WHERE SName = 'TimeZone';

        SELECT @AffRate = Rate 
        FROM dbo.Aff_f_ExchangeRate_Sel(@CPADate, @AffCurrency, 0);
    
        -- =============================================
        -- SECTION 2: INITIALIZE TEMPORARY TABLES
        -- =============================================
        
        -- Eligible groups for processing
        CREATE TABLE #QualifiedGroups (
            ID INT,
			GroupId INT,
            AffId INT,
            StartSchedule DATE,
			EndSchedule DATE
        );
        
        -- Qualified members for CPA processing
        CREATE TABLE #QualifiedMembers (
            MemberCPA_ID INT,
            AffId INT,
            GroupId INT,
            CustId INT,
            CPAAmount MONEY,
            StatusId INT,
			ID INT,
            HoldingQualifiedDate DATE,
            FirstTimeDepositDate DATETIME
        );

        -- Not qualified groups for processing
        CREATE TABLE #NotQualifiedGroups (
            ID INT,
            GroupId INT,
            AffId INT,
            StartSchedule DATE,
			EndSchedule DATE
        );
        
        -- Not qualified members for CPA processing
        CREATE TABLE #NotQualifiedMembers (
            MemberCPA_ID INT,
            AffId INT,
            GroupId INT,
            CustId INT,
            CPAAmount MONEY,
            StatusId INT,
            ID INT
        );

        -- Quota status tracking
        CREATE TABLE #QuotaStatus (
            AffId INT,
            GroupId INT,
            Quota INT,
            PaidCount INT,
            Remain INT
        );
        
        -- Rollback backup tables (created early)
        CREATE TABLE #MemberCPABackup (
            AffId INT,
            GroupId INT,
            CustId INT,
            OriginalStatusId INT,
            OriginalRefId BIGINT,
            OriginalCPADate DATETIME,
            OriginalUpdatedDate DATETIME
        );
        
        -- Backup table for rptAffiliateCPA changes
        CREATE TABLE #rptAffiliateCPABackup (
            ID INT,
            OriginalApprovedAmount MONEY,
            OriginalApprovedDate DATE,
            OriginalIsProcessed BIT,
            OriginalUpdatedDate DATETIME
        );
        
        -- Transaction tracking tables
        /*
        CREATE TABLE #SubCPATransIds (
            TransId BIGINT,
            ParentAffId INT
        );
        
        CREATE TABLE #SubCPATransSubDetailIds (
            TransId BIGINT,
            AffId INT
        );
        */
        
        CREATE TABLE #MainPayouts (
            AffId INT,
            TransType SMALLINT,
            CPAAmount MONEY,
            RefId BIGINT
        );
        -- =============================================
        -- SECTION 3: LOAD ELIGIBLE GROUPS AND MEMBERS
        -- =============================================
        
        -- Get QualifiedGroups groups for processing
        INSERT INTO #QualifiedGroups (ID, GroupId, AffId, StartSchedule, EndSchedule)
        SELECT r.ID,
			   r.GroupId, 
               r.AffId,
               r.StartSchedule,
               r.EndSchedule
        FROM dbo.rptAffiliateCPA r WITH (NOLOCK)
        WHERE r.Status = 'Qualified'
          AND r.IsProcessed = 0;
        
        -- Get qualified members
        INSERT INTO #QualifiedMembers (MemberCPA_ID, AffId, GroupId, CustId, CPAAmount, StatusId, ID, HoldingQualifiedDate, FirstTimeDepositDate)
        SELECT m.MemberCPA_ID,
               m.AffId, 
               m.GroupId, 
               m.CustId, 
               m.CPAAmount, 
               m.StatusId,
               eg.ID,
               m.HoldingQualifiedDate,
               mi.FirstDepositDate
        FROM dbo.MemberCPA m WITH (NOLOCK)
        INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON m.CustId = mi.CustId
        INNER JOIN #QualifiedGroups eg ON m.GroupId = eg.GroupId AND m.AffId = eg.AffId
        WHERE m.StatusId = 2
          AND m.HoldingQualifiedDate BETWEEN eg.StartSchedule AND eg.EndSchedule;

        -- Get NotQualifiedGroups groups for processing
        INSERT INTO #NotQualifiedGroups (ID, GroupId, AffId, StartSchedule, EndSchedule)
        SELECT r.ID,
			   r.GroupId, 
               r.AffId,
               r.StartSchedule,
               r.EndSchedule
        FROM dbo.rptAffiliateCPA r WITH (NOLOCK)
        WHERE r.Status = 'Not Qualified'
          AND r.IsProcessed = 0;

        -- Get not qualified members
        INSERT INTO #NotQualifiedMembers (MemberCPA_ID, AffId, GroupId, CustId, CPAAmount, StatusId)
        SELECT m.MemberCPA_ID,
               m.AffId, 
               m.GroupId, 
               m.CustId, 
               m.CPAAmount, 
               m.StatusId
        FROM dbo.MemberCPA m WITH (NOLOCK)
        INNER JOIN #NotQualifiedGroups ng ON m.GroupId = ng.GroupId AND m.AffId = ng.AffId
        WHERE m.StatusId = 2
          AND m.HoldingQualifiedDate BETWEEN ng.StartSchedule AND ng.EndSchedule;
          
        -- =============================================
        -- SECTION 4: QUOTA VALIDATION AND BACKUP
        -- =============================================
        
        -- Calculate quota status for qualified groups only
        -- Note: Quota = 0 means unlimited quota (no restriction)
        INSERT INTO #QuotaStatus (AffId, GroupId, Quota, PaidCount, Remain)
        SELECT quota_data.AffId,
               quota_data.GroupId, 
               quota_data.Quota,
               ISNULL(paid_data.PaidCount, 0) AS PaidCount,
               CASE 
                   WHEN quota_data.Quota = 0 THEN NULL  -- NULL indicates unlimited quota
                   ELSE quota_data.Quota - ISNULL(paid_data.PaidCount, 0)
               END AS Remain
        FROM (
            SELECT qg.AffId, 
                   qg.GroupId, 
                   gs.Quota
            FROM #QualifiedGroups qg
            INNER JOIN dbo.CPAGroupSetting gs WITH (NOLOCK)
                ON qg.GroupId = gs.GroupId 
               AND gs.ToDate = @Todate
        ) quota_data
        OUTER APPLY (
            SELECT COUNT(CustId) AS PaidCount
            FROM dbo.MemberCPA WITH (NOLOCK)
            WHERE AffId = quota_data.AffId
              AND GroupId = quota_data.GroupId
              AND StatusId = 3
        ) paid_data;
        
        -- Create backup of all members that might be affected
        INSERT INTO #MemberCPABackup (AffId, GroupId, CustId, OriginalStatusId, OriginalRefId, OriginalCPADate, OriginalUpdatedDate)
        SELECT m.AffId, m.GroupId, m.CustId, m.StatusId, m.RefId, m.CPADate, m.UpdatedDate
        FROM dbo.MemberCPA m WITH (NOLOCK)
        WHERE EXISTS (
            SELECT 1 
            FROM #QualifiedMembers qm 
            WHERE m.AffId = qm.AffId 
              AND m.GroupId = qm.GroupId 
              AND m.CustId = qm.CustId
        )
        OR EXISTS (
            SELECT 1 
            FROM #NotQualifiedMembers nqm 
            WHERE m.AffId = nqm.AffId 
              AND m.GroupId = nqm.GroupId 
              AND m.CustId = nqm.CustId
        );
        
        -- Create backup of rptAffiliateCPA records that will be modified
        INSERT INTO #rptAffiliateCPABackup (ID, OriginalApprovedAmount, OriginalApprovedDate, OriginalIsProcessed, OriginalUpdatedDate)
        SELECT r.ID, r.ApprovedAmount, r.ApprovedDate, r.IsProcessed, r.UpdatedDate
        FROM dbo.rptAffiliateCPA r WITH (NOLOCK)
        WHERE r.ID IN (
            SELECT ID FROM #QualifiedGroups
            UNION
            SELECT ID FROM #NotQualifiedGroups
        );
        
        -- Apply quota restrictions - mark excess members as quota exceeded
        -- Note: Only apply quota restrictions when Quota > 0 (limited quota)
        --       When Quota = 0, it means unlimited quota, so no members should be marked as exceeded
        WITH cte_ExcessMembers AS (
            SELECT qs.AffId, 
                   qs.GroupId, 
                   qs.Quota, 
                   qs.PaidCount, 
                   qs.Remain,
                   qm.CustId, 
                   qm.CPAAmount,
                   ROW_NUMBER() OVER (
                       PARTITION BY qs.AffId, qs.GroupId 
                       ORDER BY qm.HoldingQualifiedDate ASC,
                                qm.FirstTimeDepositDate ASC
                   ) AS RowNum
            FROM #QuotaStatus qs
            INNER JOIN #QualifiedMembers qm 
                ON qs.AffId = qm.AffId 
               AND qs.GroupId = qm.GroupId
            WHERE qs.Quota > 0      -- Only process groups with limited quota
              AND qs.Remain IS NOT NULL  -- Skip unlimited quota (Remain = NULL)
        )
        UPDATE m WITH (UPDLOCK, ROWLOCK)
        SET m.StatusId = 5, -- Quota exceeded
			m.CPADate = @CPADatePlus1,
			m.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
        FROM dbo.MemberCPA m
        INNER JOIN cte_ExcessMembers cem 
            ON m.AffId = cem.AffId 
           AND m.GroupId = cem.GroupId 
           AND m.CustId = cem.CustId
        WHERE cem.RowNum > cem.Remain;
        
        -- Track schedules that became empty due to quota exceeded
        CREATE TABLE #QuotaExceededSchedules (
            ID INT,
            AffId INT,
            GroupId INT
        );
        
        -- Identify schedules where all members exceed quota
        INSERT INTO #QuotaExceededSchedules (ID, AffId, GroupId)
        SELECT DISTINCT qm.ID, qm.AffId, qm.GroupId
        FROM #QualifiedMembers qm
        WHERE NOT EXISTS (
            SELECT 1 
            FROM #QualifiedMembers qm2 
            INNER JOIN dbo.MemberCPA m WITH (NOLOCK)
                ON m.AffId = qm2.AffId 
               AND m.GroupId = qm2.GroupId 
               AND m.CustId = qm2.CustId
            WHERE qm2.ID = qm.ID
              AND qm2.AffId = qm.AffId 
              AND qm2.GroupId = qm.GroupId
              AND m.StatusId != 5  -- Has at least one non-exceeded member
        );

        -- Remove quota-exceeded members from processing list
        DELETE qm
        FROM #QualifiedMembers qm
        INNER JOIN dbo.MemberCPA m WITH (NOLOCK) 
            ON m.AffId = qm.AffId 
           AND m.GroupId = qm.GroupId 
           AND m.CustId = qm.CustId
        WHERE m.StatusId = 5;
        
        -- =============================================
        -- SECTION 5: SUB-CPA CALCULATION
        -- =============================================
        
        /*
        -- Build parent hierarchy for sub-CPA
        CREATE TABLE #ParentHierarchy (
            AffId INT,
            ParentAffId INT,
            Level INT,
            ParentGroupId INT,
            SubCommRate FLOAT,
            CPAAmount MONEY
        );
        
        INSERT INTO #ParentHierarchy (AffId, ParentAffId, Level, ParentGroupId, SubCommRate, CPAAmount)
        SELECT 
               ai.AffId, 
               parent_data.ParentAffId, 
               parent_data.Level, 
               parent_data.ParentGroupId, 
               parent_data.SubCommRate,
               SUM(qm.CPAAmount) AS CPAAmount
        FROM dbo.AffInfo ai WITH (NOLOCK)
        INNER JOIN #QualifiedMembers qm ON ai.AffId = qm.AffId
        OUTER APPLY (
            SELECT CAST(f.val AS INT) AS ParentAffId, 
                   f.Id AS Level,
                   parent_ai.GroupId AS ParentGroupId,
                   cgs.SubCommRate
            FROM dbo.Aff_f_StringSplit(ai.AllParentAffId, ',') f
            INNER JOIN dbo.AffInfo parent_ai WITH (NOLOCK) 
                ON CAST(f.val AS INT) = parent_ai.AffId
            INNER JOIN dbo.CPAGroupSetting cgs WITH (NOLOCK) 
                ON parent_ai.GroupId = cgs.GroupId 
               AND cgs.ToDate = @Todate
            INNER JOIN dbo.CommGroup cg WITH (NOLOCK) 
                ON parent_ai.GroupId = cg.GroupId 
               AND cg.IsDeleted = 0
            WHERE f.Id <= @MaxLevels
        ) AS parent_data
        WHERE ai.ParentAffId IS NOT NULL
        GROUP BY
               ai.AffId, 
               parent_data.ParentAffId, 
               parent_data.Level, 
               parent_data.ParentGroupId, 
               parent_data.SubCommRate;
        
        -- Calculate sub-CPA amounts with cumulative rates
        CREATE TABLE #SubCPACalculation (
            AffId INT,
            ParentAffId INT,
            Level INT,
            ParentGroupId INT,
            SubCommRate FLOAT,
            CumulativeRate FLOAT,
            CPAAmount MONEY,
            SubCPAAmount MONEY,
            TransType SMALLINT
        );
        
        WITH cte_CumulativeCPA AS (
            SELECT ph.AffId,
                   ph.ParentAffId,
                   ph.Level,
                   ph.ParentGroupId,
                   ph.SubCommRate,
                   ph.CPAAmount,
                   a.CumulativeRate
            FROM #ParentHierarchy ph
            CROSS APPLY (
							SELECT 
								-- Calculate cumulative CPA rate using EXP/LOG for product
								   EXP(SUM(LOG(ph2.SubCommRate)) OVER (
									   PARTITION BY ph.AffId 
									   ORDER BY ph2.Level ASC
								   )) AS CumulativeRate
							FROM #ParentHierarchy ph2 
							WHERE ph.AffId = ph2.AffId 
								AND ph2.Level <= ph.Level
			   ) a
        )
        INSERT INTO #SubCPACalculation 
        (AffId, ParentAffId, Level, ParentGroupId, SubCommRate, CumulativeRate, CPAAmount, SubCPAAmount, TransType)
        SELECT ccc.AffId,
               ccc.ParentAffId,
               ccc.Level,
               ccc.ParentGroupId,
               ccc.SubCommRate,
               ccc.CumulativeRate,
               SUM(ccc.CPAAmount) AS CPAAmount,
               SUM(ccc.CPAAmount * ccc.CumulativeRate) AS SubCPAAmount,
               @SubTransType AS TransType
        FROM cte_CumulativeCPA ccc
        GROUP BY
               ccc.AffId,
               ccc.ParentAffId,
               ccc.Level,
               ccc.ParentGroupId,
               ccc.SubCommRate,
               ccc.CumulativeRate;
        */
        
        -- =============================================
        -- SECTION 6: CREATE TRANSACTION RECORDS
        -- =============================================
        
        /*
        -- Create sub-CPA transactions (grouped by parent affiliate)
        INSERT INTO dbo.AffTrans (
            AffId, TransDate, CompletedDate, Amount, Status, Description, 
            Creator, TransType, RefId, AffCurrency, AffRate, WinlostDate
        )
        OUTPUT INSERTED.TransId, INSERTED.AffId
        INTO #SubCPATransIds (TransId, ParentAffId)
        SELECT scc.ParentAffId,
               @TransDate,
               @TransDate,
               SUM(scc.SubCPAAmount) AS TotalSubCPAAmount,
               'Completed',
               'Sub CPA Amount',
               @CreatorId,
               @SubTransType,
               NULL,
               @AffCurrency,
               @AffRate,
               @CPADatePlus1
        FROM #SubCPACalculation scc
        GROUP BY scc.ParentAffId
        HAVING SUM(scc.SubCPAAmount) > 0;

        -- Create sub-CPA detail records
        INSERT INTO dbo.AffTransSubDetail (
            AffId, WinlostDate, TransType, TransDate, DownlineAffId, DownlineAmount, CumulativeSubRate, Amount
        )
        OUTPUT INSERTED.TransId, INSERTED.AffId
        INTO #SubCPATransSubDetailIds (TransId, AffId)
        SELECT 
            scc.ParentAffId,
            @CPADatePlus1,
            @SubTransType,
            @TransDate,
            scc.AffId AS DownlineAffId,
            scc.CPAAmount AS DownlineAmount,
            scc.CumulativeRate,
            scc.SubCPAAmount
        FROM #SubCPACalculation scc;
        */
        
        -- Create main CPA transactions (grouped by affiliate)
        ;WITH cte_AffiliatePayouts AS (
            SELECT AffId,
                   SUM(CPAAmount) AS TotalCPAAmount,
                   @MainTransType AS TransType
            FROM #QualifiedMembers
            GROUP BY AffId
            HAVING SUM(CPAAmount) > 0
        )
        INSERT INTO dbo.AffTrans (
            AffId, TransDate, CompletedDate, Amount, Status, Description, 
            Creator, TransType, RefId, AffCurrency, AffRate, WinlostDate
        )
        OUTPUT INSERTED.AffId, 
               @MainTransType, 
               INSERTED.Amount, 
               INSERTED.TransId
        INTO #MainPayouts (AffId, TransType, CPAAmount, RefId)
        SELECT cap.AffId,
               @CPADatePlus1,
               @TransDate,
               cap.TotalCPAAmount,
               'Approved',
               'CPA Earning',
               @CreatorId,
               cap.TransType,
               NULL,
               @AffCurrency,
               @AffRate,
               @CPADatePlus1
        FROM cte_AffiliatePayouts cap;
        
        -- =============================================
        -- SECTION 7: UPDATE RECORDS AND FINALIZE
        -- =============================================
        
        -- Update member statuses to "Paid" (StatusId = 3)
        ;WITH cte_PaymentUpdates AS (
            SELECT qm.AffId, 
                   qm.GroupId, 
                   qm.CustId, 
                   3 AS NewStatusId,
                   mp.RefId
            FROM #QualifiedMembers qm
            INNER JOIN #MainPayouts mp ON qm.AffId = mp.AffId
        )
        UPDATE m WITH (UPDLOCK, ROWLOCK)
        SET m.StatusId = cpu.NewStatusId,
            m.RefId = cpu.RefId,
            m.CPADate = @CPADatePlus1,
            m.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
        FROM dbo.MemberCPA m 
        INNER JOIN cte_PaymentUpdates cpu 
            ON m.AffId = cpu.AffId 
           AND m.GroupId = cpu.GroupId 
           AND m.CustId = cpu.CustId;
        
        -- Update member statuses to "Not Qualified" (StatusId = 6)
        UPDATE m
        SET m.StatusId = 6,  -- Not Qualified
            m.CPADate = @CPADatePlus1,
            m.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
        FROM dbo.MemberCPA m WITH (UPDLOCK, ROWLOCK)
        WHERE EXISTS (
            SELECT 1 
            FROM #NotQualifiedMembers nqm 
            WHERE m.AffId = nqm.AffId 
              AND m.GroupId = nqm.GroupId 
              AND m.CustId = nqm.CustId
        );

        -- Update rptAffiliateCPA - QualifiedGroups records as processed
        ;WITH cte_SchedulePayouts AS (
            SELECT ID,
                   SUM(CPAAmount) AS TotalCPAAmount
            FROM #QualifiedMembers
			GROUP BY ID
        )
        UPDATE r
        SET r.ApprovedAmount = cte.TotalCPAAmount,
            r.ApprovedDate = @CPADatePlus1,
            r.IsProcessed = 1,
            r.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
        FROM dbo.rptAffiliateCPA r WITH (UPDLOCK, ROWLOCK)
        INNER JOIN cte_SchedulePayouts cte ON r.ID = cte.ID;

        -- Update rptAffiliateCPA - NotQualifiedGroups records as processed
        UPDATE r
        SET r.IsProcessed = 1,
            r.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
        FROM dbo.rptAffiliateCPA r WITH (UPDLOCK, ROWLOCK)
        WHERE r.ID IN (SELECT ID FROM #NotQualifiedGroups);

        -- Update rptAffiliateCPA - QuotaExceededSchedules records as processed
        UPDATE r
        SET r.ApprovedAmount = 0.00,
            r.ApprovedDate = @CPADatePlus1,
            r.IsProcessed = 1,
            r.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
        FROM dbo.rptAffiliateCPA r WITH (UPDLOCK, ROWLOCK)
        WHERE r.ID IN (SELECT ID FROM #QuotaExceededSchedules);
                        
        -- Success - set return values
        SET @ErrCode = 0;
        SET @ErrMsg = 'CPA Approval Period processed successfully';
             
    END TRY
    BEGIN CATCH
        -- =============================================
        -- ERROR HANDLING AND ROLLBACK
        -- =============================================
        
        -- Capture error information
        SET @ErrCode = ERROR_NUMBER();
        SET @ErrMsg = 'Error in Task_Aff_CPAApprovalPeriod: ' + ERROR_MESSAGE() + 
                     ' (Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ')';
        
        -- Perform manual rollback operations in reverse order
        
        -- 1. Rollback rptAffiliateCPA updates (restore original values)
        UPDATE r WITH (UPDLOCK, ROWLOCK)
        SET r.ApprovedAmount = a.OriginalApprovedAmount,
            r.ApprovedDate = a.OriginalApprovedDate,
            r.IsProcessed = a.OriginalIsProcessed,
            r.UpdatedDate = a.OriginalUpdatedDate
        FROM dbo.rptAffiliateCPA r
        INNER JOIN #rptAffiliateCPABackup a ON r.ID = a.ID;
        
        -- 2. Rollback MemberCPA updates (restore original values)
        UPDATE m WITH (UPDLOCK, ROWLOCK)
        SET m.StatusId = a.OriginalStatusId,
            m.RefId = a.OriginalRefId,
            m.CPADate = a.OriginalCPADate,
            m.UpdatedDate = a.OriginalUpdatedDate
        FROM dbo.MemberCPA m
        INNER JOIN #MemberCPABackup a 
            ON m.AffId = a.AffId 
           AND m.GroupId = a.GroupId 
           AND m.CustId = a.CustId;
        
        -- 3. Delete main CPA transaction records
        DELETE aft
		FROM dbo.AffTrans aft WITH (ROWLOCK)
        WHERE EXISTS (
            SELECT 1 
            FROM #MainPayouts m
            WHERE m.RefId IS NOT NULL 
				AND m.RefId = aft.TransId
        );
        
        /*
        -- 3. Delete sub-CPA transaction records  
        DELETE FROM dbo.AffTrans WITH (ROWLOCK)
        WHERE TransId IN (
            SELECT TransId 
            FROM #SubCPATransIds 
            WHERE TransId IS NOT NULL
        );
        
        -- 4. Delete sub-CPA detail records
        DELETE FROM dbo.AffTransSubDetail WITH (ROWLOCK)
        WHERE TransId IN (
            SELECT TransId 
            FROM #SubCPATransSubDetailIds 
            WHERE TransId IS NOT NULL
        );
        */
    END CATCH

    -- =============================================
    -- SECTION 8: CLEANUP TEMPORARY TABLES
    -- =============================================
	DROP TABLE IF EXISTS #QualifiedGroups;
	DROP TABLE IF EXISTS #QualifiedMembers;
	DROP TABLE IF EXISTS #NotQualifiedGroups;
	DROP TABLE IF EXISTS #NotQualifiedMembers;
	DROP TABLE IF EXISTS #QuotaStatus;
	DROP TABLE IF EXISTS #QuotaExceededSchedules;
	/*
	DROP TABLE IF EXISTS #ParentHierarchy;
	DROP TABLE IF EXISTS #SubCPACalculation;
	*/
	DROP TABLE IF EXISTS #MainPayouts;
	DROP TABLE IF EXISTS #MemberCPABackup;
	DROP TABLE IF EXISTS #rptAffiliateCPABackup;
	/*
	DROP TABLE IF EXISTS #SubCPATransIds;
	DROP TABLE IF EXISTS #SubCPATransSubDetailIds;
	*/

END;
GO