/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_Aff_CPAHoldingPeriod
    @CPADate DATE
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created:      20250703@Lewis
    Task:         Step 2 - CPA Holding Period Qualification
    DB:           DBAFF12B-Affiliate_12B
    
	Revisions:
        - 20250703@Lewis: Initial [RedmineID: #283530]
		- 20250930@Lewis: Enhance HoldingQualifiedDate [RedmineID: #235601]
*/
BEGIN
    SET NOCOUNT ON;

        -- =============================================
        -- SECTION 1: INPUT VALIDATION & INITIALIZATION
        -- =============================================
        
        -- Validate required parameters
        IF @CPADate IS NULL 
        BEGIN
            SET @ErrCode = 100;
            SET @ErrMsg = 'Parameter @CPADate is required and cannot be NULL';
            RETURN;
        END

        DECLARE @Todate DATETIME = '9999-12-31',
                @TimeZone SMALLINT;
        
        -- Get system settings with validation
        SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
        FROM dbo.SystemSettings WITH (NOLOCK) 
        WHERE SName = 'TimeZone';
        

        -- =============================================
        -- SECTION 2: GET ACTIVE QUALIFIED MEMBERS & GROUP HOLDING SETTINGS
        -- =============================================
        
        -- Step 1. Member selection (qualified in Step 1)
        CREATE TABLE #Member (
            AffId                   INT,
            GroupId                 INT,
            CustId                  INT,
            StatusID                INT,
			RegisteredDate		    DATETIME,
            ActiveQualifiedDate     DATETIME, --FROMDATE
            OldHoldingQualifiedDate DATETIME, --Old HQD
            CPADatePlus1		    DATETIME, --CPADate
            DeadlineHQDate          DATETIME, --RegisteredDate + ActiveDay + HoldingDay
			HoldingBetTickets	    INT,
			HoldingQualifiedDate    DATETIME,
            HoldingTickets          INT
        );
        
        INSERT INTO #Member (AffId, GroupId, CustId, StatusID, RegisteredDate, ActiveQualifiedDate, OldHoldingQualifiedDate, CPADatePlus1, DeadlineHQDate, HoldingTickets)
        SELECT m.AffId, 
               m.GroupId, 
               m.CustId, 
               m.StatusID, 
			   mi.RegisteredDate,
               m.ActiveQualifiedDate, --FROMDATE
			   IIF(DATEADD(DAY, s.HoldingDays, m.ActiveQualifiedDate) < m.HoldingQualifiedDate, DATEADD(DAY, 1, @CPADate), m.HoldingQualifiedDate), --OLD HQD
			   DATEADD(DAY, 1, @CPADate), --CPADatePlus1
			   DATEADD(DAY, s.HoldingDays - 1, m.ActiveQualifiedDate), --DeadlineHQDate
			   s.HoldingTickets
        FROM dbo.MemberCPA m WITH (NOLOCK)
		INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON m.CustId = mi.CustId
		INNER JOIN dbo.CPAGroupSetting s WITH (NOLOCK) ON s.ToDate = @Todate AND s.GroupId = m.GroupId
        WHERE m.StatusID = 0
			AND mi.RegisteredDate >= CONVERT(DATE, DATEADD(DAY, (1 - s.ActiveDays - s.HoldingDays), @CPADate))
			AND mi.RegisteredDate < DATEADD(DAY, 1, @CPADate);
        
        -- =============================================
        -- SECTION 3: CALCULATE BET TICKETS
        -- =============================================
        
        -- Step 4. Aggregate BetTickets from rptMemberDaily
        CREATE TABLE #BetTickets (
            CustId					INT,
            AffId					INT,
            BetTickets				INT,
			HoldingQualifiedDate	DATETIME,
			StatusID				INT
        );

        ; -- old pending member -- Eligibled
		WITH cte_OldHLD AS (
			SELECT r.CustId, 
				   r.AffId, 
				   SUM(r.BetCount) AS BetTickets,
				   m2.OldHoldingQualifiedDate AS HoldingQualifiedDate,
				   2 AS StatusID
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			INNER JOIN #Member m2 ON r.CustId = m2.CustId 
								  AND r.AffId = m2.AffId
			WHERE r.WinlostDate >= m2.ActiveQualifiedDate 
				AND r.WinlostDate < m2.OldHoldingQualifiedDate -- Upto Old HQD
				AND r.ProductId > 0
				AND m2.HoldingTickets > 0
				AND m2.OldHoldingQualifiedDate IS NOT NULL
			GROUP BY r.CustId, r.AffId, m2.OldHoldingQualifiedDate, m2.HoldingTickets
			HAVING SUM(r.BetCount) >= m2.HoldingTickets -- Compare setting
		)
		, -- new pending member -- Eligibled
		cte_CPADatePlus1 AS (
			SELECT r.CustId, 
				   r.AffId, 
				   SUM(r.BetCount) AS BetTickets,
				   m2.CPADatePlus1 AS HoldingQualifiedDate,
				   2 AS StatusID
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			INNER JOIN #Member m2 ON r.CustId = m2.CustId 
								  AND r.AffId = m2.AffId
			WHERE r.WinlostDate >= m2.ActiveQualifiedDate 
				AND r.WinlostDate < m2.CPADatePlus1 -- Upto CPADate
				AND r.ProductId > 0
				AND m2.HoldingTickets > 0
				AND NOT EXISTS (SELECT TOP 1 1 FROM cte_OldHLD cte WHERE cte.CustId = r.CustId) -- Exclude if qualified bet tickets with OLD range 
			GROUP BY r.CustId, r.AffId, m2.CPADatePlus1, m2.HoldingTickets
			HAVING SUM(r.BetCount) >= m2.HoldingTickets -- Compare setting
		)
		, -- new pending member -- Not Eligibled
		cte_NotEligible AS (
			SELECT r.CustId, 
				   r.AffId, 
				   SUM(r.BetCount) AS BetTickets,
				   m2.OldHoldingQualifiedDate AS HoldingQualifiedDate,
				   m2.StatusID
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			INNER JOIN #Member m2 ON r.CustId = m2.CustId 
								  AND r.AffId = m2.AffId
			WHERE r.WinlostDate >= m2.ActiveQualifiedDate 
				AND r.WinlostDate < m2.CPADatePlus1 -- Upto CPADate
				AND r.ProductId > 0
				AND m2.HoldingTickets > 0
				AND NOT EXISTS (SELECT TOP 1 1 FROM cte_OldHLD cte WHERE cte.CustId = r.CustId) -- Exclude OLD range 
				AND NOT EXISTS (SELECT TOP 1 1 FROM cte_CPADatePlus1 cte WHERE cte.CustId = r.CustId) -- Exclude CPADate range 
			GROUP BY r.CustId, r.AffId, m2.OldHoldingQualifiedDate, m2.StatusID
		)
		INSERT INTO #BetTickets (CustId, AffId, BetTickets, HoldingQualifiedDate, StatusID)
		SELECT CustId, AffId, BetTickets, HoldingQualifiedDate, StatusID FROM cte_OldHLD
		UNION ALL
		SELECT CustId, AffId, BetTickets, HoldingQualifiedDate, StatusID FROM cte_CPADatePlus1
		UNION ALL
		SELECT CustId, AffId, BetTickets, HoldingQualifiedDate, StatusID FROM cte_NotEligible

        -- =============================================
        -- SECTION 6: APPLY HOLDING QUALIFICATION LOGIC
        -- =============================================

        -- Step 5. Update #Member -- processing eligibled (2)
        UPDATE m
        SET m.HoldingBetTickets = b.BetTickets,
			m.HoldingQualifiedDate = b.HoldingQualifiedDate,
			m.StatusID = b.StatusID
        FROM #Member m
        INNER JOIN #BetTickets b ON m.CustId = b.CustId 
                               AND m.AffId = b.AffId;

        -- Step 6.  Update #Member -- processing <> eligibled (2)
        UPDATE t
        SET
			t.HoldingBetTickets = CASE 
									   WHEN t.HoldingTickets = 0 THEN NULL  -- Skip holding period
                                       ELSE ISNULL(t.HoldingBetTickets,0) -- no betcount
                                    END,
			t.HoldingQualifiedDate = CASE 
									   WHEN t.HoldingTickets = 0 THEN t.ActiveQualifiedDate  -- Skip holding period
                                       ELSE t.HoldingQualifiedDate -- no betcount
                                    END,
            t.StatusID = CASE 
                           WHEN t.HoldingTickets = 0 THEN 2  -- Skip holding period
                           WHEN ISNULL(t.HoldingBetTickets,0) < t.HoldingTickets AND @CPADate < t.DeadlineHQDate THEN t.StatusID
                           ELSE 1
                        END
        FROM #Member t
		WHERE t.StatusID <> 2;

        -- =============================================
        -- SECTION 7: UPDATE MEMBER CPA TABLE
        -- =============================================
        
        -- Step 7. Update MemberCPA
        UPDATE m WITH (UPDLOCK, ROWLOCK)
        SET m.HoldingQualifiedDate = t.HoldingQualifiedDate,
            m.HoldingBetTickets    = t.HoldingBetTickets,
			m.HoldingExpiredDate   = t.DeadlineHQDate,
            m.StatusId             = t.StatusID,
            m.UpdatedDate          = DATEADD(HOUR, @TimeZone, GETUTCDATE())
        FROM dbo.MemberCPA m
        INNER JOIN #Member t ON m.AffId = t.AffId 
                            AND m.CustId = t.CustId 
                            AND m.GroupId = t.GroupId;

        -- =============================================
        -- SECTION 8: CLEANUP AND SUMMARY
        -- =============================================

        -- Cleanup temporary tables
        DROP TABLE IF EXISTS #Member;
        DROP TABLE IF EXISTS #BetTickets;
       
END;
GO