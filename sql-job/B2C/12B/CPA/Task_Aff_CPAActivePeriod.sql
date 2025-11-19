/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_CPAActivePeriod]
    @CPADate DATE,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(4000) = NULL OUTPUT
AS
/*
    Created: 20250620@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Job - Calculate CPA Active Period qualification for players

    Revisions:
        - 20250620@Sophia: Initialize SP [Redmine: # 230662]
        - 20250930@Sally: Return Re-DepositInfo [Redmine: #236838]
 
*/
BEGIN
    SET NOCOUNT ON;
    IF @CPADate IS NULL 
    BEGIN
        SET @ErrCode = 100;
        SET @ErrMsg = N'CPADate is NULL.';
        RETURN
    END
    
    -- 1. Declare and set @BaseCurrency
    DECLARE @BaseCurrency INT, @ToDate DATE = '9999-12-31'
    SELECT @BaseCurrency = ISNULL(t.ExchangeId, CONVERT(INT, SValue))
    FROM dbo.SystemSettings s WITH (NOLOCK)
    LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON CONVERT(INT, SValue) = t.TpExchangeId
    WHERE SName = 'AffCurrency';

    -- 2. Create temp table for GroupId/CountryCode/CPAGroupSettingID pairs using STRING_SPLIT
    CREATE TABLE #GroupCountry (
        GroupId INT,
        CountryCode VARCHAR(5),
        ActiveDays SMALLINT,
        HoldingDays SMALLINT,
        StartDate DATE,
		RedepositDays SMALLINT
    );

    INSERT INTO #GroupCountry (GroupId, CountryCode, ActiveDays, HoldingDays, StartDate, RedepositDays)
    SELECT
        cgs.GroupId,
        TRIM(s.value) AS CountryCode,
        cgs.ActiveDays,
        cgs.HoldingDays,
        cgs.StartDate,
		cgs.RedepositDays
    FROM CPAGroupSetting cgs WITH (NOLOCK)
    CROSS APPLY STRING_SPLIT(cgs.CountryCodes, ',') s
    WHERE cgs.ToDate = @Todate
      AND NOT EXISTS (SELECT TOP 1 1 FROM CommGroup cg WITH (NOLOCK) WHERE cg.GroupId = cgs.GroupId AND cg.IsDeleted = 1);
      

    -- 3. Create unified currency-country mapping (TPExchange priority) and map GroupId to Currency, including CPAGroupSettingID
    CREATE TABLE #GroupCurrency (
        GroupId INT,
        CurrencyID INT,
        ActiveDays SMALLINT,
        HoldingDays SMALLINT,
        StartDate DATE,
		RedepositDays SMALLINT
    );

    INSERT INTO #GroupCurrency (GroupId, CurrencyID, ActiveDays, HoldingDays, StartDate, RedepositDays)
    SELECT gc.GroupId, tpe.TPExchangeID, gc.ActiveDays, gc.HoldingDays, gc.StartDate, gc.RedepositDays
    FROM #GroupCountry gc
    INNER JOIN TPExchange tpe WITH (NOLOCK) ON gc.CountryCode = tpe.CountryCode
    UNION ALL
    SELECT gc.GroupId, ex.ExchangeID, gc.ActiveDays, gc.HoldingDays, gc.StartDate, gc.RedepositDays
    FROM #GroupCountry gc
    INNER JOIN Exchange ex WITH (NOLOCK) ON gc.CountryCode = ex.CountryCode
    WHERE NOT EXISTS (SELECT 1 FROM TPExchange tpe WITH (NOLOCK) WHERE tpe.CountryCode = gc.CountryCode);

    -- Create indexes on #GroupCurrency for better performance
    CREATE CLUSTERED INDEX IX_GroupCurrency_GroupId_CurrencyID ON #GroupCurrency (GroupId, CurrencyID);


    -- 4. Get deal settings by GroupId, GroupProductId, and TierId
    CREATE TABLE #DealSetting (
        GroupId INT,
        GroupProductId INT,
		ModeDeal TINYINT, --- 1: Only FDM;  2: Other
        TierId INT,
        MinFDM MONEY,
        MaxFDM MONEY,
        MinTotalDeposit MONEY,
        MaxTotalDeposit MONEY,
        MinTO MONEY,
        MaxTO MONEY,
        CPAAmount MONEY,
        MaxTier TINYINT -- New column for max TierId per group/product
    );

    INSERT INTO #DealSetting (GroupId, GroupProductId, ModeDeal, TierId, MinFDM, MaxFDM, MinTotalDeposit, MaxTotalDeposit, MinTO, MaxTO, CPAAmount, MaxTier)
    SELECT
        ts.GroupId,
        ts.GroupProductId,
		CASE WHEN ts.MinTotalDeposit IS NULL AND ts.MinTO IS NULL AND ts.minFDM IS NOT NULL THEN 1 ELSE 2 END AS ModeDeal,
        ts.TierId,
        ts.MinFDM,
        ts.MaxFDM,
        ts.MinTotalDeposit,
        ts.MaxTotalDeposit,
        ts.MinTO,
        ts.MaxTO,
        ts.CPAAmount,
        mt.MaxTier
    FROM CPATierSetting ts WITH (NOLOCK)
    INNER JOIN (
        SELECT GroupId, GroupProductId, MAX(TierId) AS MaxTier
        FROM CPATierSetting WITH (NOLOCK)
        WHERE ToDate = @Todate
        GROUP BY GroupId, GroupProductId
        ) mt ON ts.GroupId = mt.GroupId AND ts.GroupProductId = mt.GroupProductId
    WHERE NOT EXISTS (
                        SELECT TOP 1 1 FROM CommGroup cg WITH (NOLOCK)
                        WHERE cg.GroupId = ts.GroupId AND cg.IsDeleted = 1
                    )
      AND ts.ToDate = @Todate;
      
    -- Create indexes on #DealSetting for better performance
    CREATE CLUSTERED INDEX IX_DealSetting_GroupId ON #DealSetting (GroupId);

    -- 5. Create temp table for player, affiliate, and deal info (add Currency, rptFromDate, rptToDate)
    CREATE TABLE #PlayerDeal (
        CustId INT,
        AffId INT,
        GroupId INT,
        ActiveDays SMALLINT,
        HoldingDays SMALLINT,
        RegisteredDate DATE,
        FDM MONEY,
		FirstDepositDate DATE,
		ExpiredRedepositDate DATE,
        Currency INT,
        rptFromDate DATE,
        rptToDate DATE,
        OldActiveQDate DATE, -- New column for previous ActiveQualifiedDate
        DeadlineActiveQDate DATE -- renamed from FinalActiveQDate
    );

    -- 5a. Populate #PlayerDeal for existing players in MemberCPA (for recalculation)
    INSERT INTO #PlayerDeal (CustId, AffId, GroupId, ActiveDays, HoldingDays, RegisteredDate, FDM, FirstDepositDate, ExpiredRedepositDate, Currency, rptFromDate, rptToDate, OldActiveQDate, DeadlineActiveQDate)
    SELECT pd.CustId, pd.AffId, pd.GroupId, pd.ActiveDays, pd.HoldingDays, pd.RegisteredDate, pd.FDM, pd.FirstDepositDate, pd.ExpiredRedepositDate, pd.Currency, pd.rptFromDate
        ,CASE WHEN (pd.OldActiveQDate < pd.rptToDate AND pd.OldActiveQDate IS NOT NULL) THEN pd.OldActiveQDate ELSE pd.rptToDate END AS rptToDate
        ,pd.OldActiveQDate, pd.DeadlineActiveQDate
    FROM(    
        SELECT
            mi.CustId,
            mi.AffId,
            ai.GroupId,
            gc.ActiveDays,         -- Use ActiveDays from #GroupCurrency
            gc.HoldingDays,        -- Use HoldingDays from #GroupCurrency
            mi.RegisteredDate,
            ISNULL(mi.FirstDepositAmount, 0) * ISNULL(exr.Rate, 1) AS FDM,
            CAST(mi.FirstDepositDate AS DATE) AS FirstDepositDate,
            CASE WHEN ISNULL(gc.RedepositDays, 0) = 0 THEN NULL ELSE CONVERT(DATE, DATEADD(DAY, gc.RedepositDays - 1, mi.FirstDepositDate)) END AS ExpiredRedepositDate,
            mi.Currency,
            mi.RegisteredDate AS rptFromDate,
            CASE WHEN CONVERT(DATE, DATEADD(DAY, gc.ActiveDays - 1, mi.RegisteredDate)) < @CPADate
                    THEN CONVERT(DATE, DATEADD(DAY, gc.ActiveDays , mi.RegisteredDate))  --   Ensure rptToDate is inclusive of the last day
                    ELSE DATEADD(DAY, 1, @CPADate) --   Ensure rptToDate is inclusive of the last day
                END
            AS rptToDate,
            mc.ActiveQualifiedDate AS OldActiveQDate, -- get from MemberCPA
            CONVERT(DATE, DATEADD(DAY, gc.ActiveDays, mi.RegisteredDate)) AS DeadlineActiveQDate
        FROM AffGroupHistory ai WITH (NOLOCK)
        INNER JOIN #GroupCurrency gc ON  gc.GroupId = ai.GroupId
        INNER JOIN MemberInfo mi WITH (NOLOCK) ON gc.CurrencyID = mi.Currency AND ai.AffId = mi.AffId  
        INNER JOIN MemberCPA mc WITH (NOLOCK) ON  mc.CustID = mi.CustId 
        LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
        CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(mi.FirstDepositDate, ISNULL(t.ExchangeId, mi.Currency), @BaseCurrency) exr
        WHERE mi.RegisteredDate >= DATEADD(DAY, (1 - gc.ActiveDays - gc.HoldingDays), @CPADate)
			AND mi.RegisteredDate < DATEADD(DAY, 1, @CPADate)
			AND mi.Status = 1
			AND mi.IsRemoved = 0
			AND mi.RegisteredDate >= gc.StartDate
			AND mc.StatusId NOT IN (3,4,5,6)
			AND ai.ToDate = @Todate
			AND EXISTS ( SELECT TOP 1 1 FROM AffInfo af WITH (NOLOCK) WHERE af.AffId = ai.AffId AND af.IsClosed <> 1 AND af.Status = 'Approved' AND af.IsRejected <> 1 )
    ) pd
    

    -- Create indexes on #PlayerDeal for better performance
    CREATE NONCLUSTERED INDEX IX_PlayerDeal_CustId ON #PlayerDeal (CustId);
    CREATE CLUSTERED INDEX IX_PlayerDeal_GroupId ON #PlayerDeal (GroupId);   

    -- 7. Create temp table for player product summary
    CREATE TABLE #PlayerProductSummary (
        CustId INT,
        AffId INT,
        GroupId INT,
        GroupProductId INT,
        ProductId INT,
        ActiveQualifiedDate DATE,
        TotalDeposit MONEY,
        Turnover MONEY,
        BetTickets INT,
        FDM MONEY
    );

     -- 7a. Old active period summaries and insert
    WITH TO_Summary_OldActive AS (
        SELECT
            pd.CustId,
            pd.AffId,
            pd.GroupId,
            cps.GroupProductId,
            cps.ProductId,
            pd.rptToDate AS ActiveQualifiedDate,
            SUM(rd.Turnover * ISNULL(exr.Rate, 1)) AS Turnover,
            SUM(rd.BetCount) AS BetTickets
        FROM #PlayerDeal pd
        INNER JOIN CPAProductSetting cps WITH (NOLOCK) ON pd.GroupId = cps.GroupId AND cps.ToDate = @Todate
        INNER JOIN rptMemberDaily rd WITH (NOLOCK) ON pd.CustId = rd.CustId AND rd.ProductId = cps.ProductId
        LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON pd.Currency = t.TpExchangeId
        CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(rd.WinlostDate, ISNULL(t.ExchangeId, pd.Currency), @BaseCurrency) exr
        WHERE rd.WinlostDate >= pd.rptFromDate
          AND rd.WinlostDate < pd.rptToDate  
          AND pd.OldActiveQDate IS NOT NULL
        GROUP BY pd.CustId, pd.AffId, pd.GroupId, cps.GroupProductId, cps.ProductId, pd.rptToDate
    ),
    Deposit_Summary_OldActive AS (
        SELECT
            pd.CustId,
            pd.AffId,
            pd.GroupId,
            -1 AS GroupProductId,
            -1 AS ProductId,
            pd.rptToDate AS ActiveQualifiedDate,
            SUM(rd.Deposit * ISNULL(exr.Rate, 1)) AS TotalDeposit
        FROM #PlayerDeal pd
        INNER JOIN rptMemberDaily rd WITH (NOLOCK) ON pd.CustId = rd.CustId
        CROSS APPLY (
            SELECT TOP 1 1 AS HasMinTotalDeposit
            FROM #DealSetting ds2
            WHERE ds2.GroupId = pd.GroupId AND ds2.MinTotalDeposit IS NOT NULL
        ) checkMinTotalDeposit
        LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON pd.Currency = t.TpExchangeId
        CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(rd.WinlostDate, ISNULL(t.ExchangeId, pd.Currency), @BaseCurrency) exr
        WHERE rd.WinlostDate >= pd.rptFromDate
          AND rd.WinlostDate < pd.rptToDate 
          AND pd.OldActiveQDate IS NOT NULL
          AND rd.ProductId = -1
        GROUP BY pd.CustId, pd.AffId, pd.GroupId, pd.rptToDate
    ),
    FDM_Summary_OldActive AS (
        SELECT
            pd.CustId,
            pd.AffId,
            pd.GroupId,
            -1 AS GroupProductId,
            -1 AS ProductId,
            pd.rptToDate AS ActiveQualifiedDate,
            pd.FDM
        FROM #PlayerDeal pd
        CROSS APPLY (
            SELECT TOP 1 1 AS HasMinFDM
            FROM #DealSetting ds2
            WHERE ds2.GroupId = pd.GroupId AND ds2.MinFDM IS NOT NULL
        ) checkMinFDM
        WHERE pd.FirstDepositDate >= pd.rptFromDate
          AND pd.FirstDepositDate < pd.rptToDate
        GROUP BY pd.CustId, pd.AffId, pd.GroupId, pd.FDM, pd.rptToDate
    )
    -- Insert old active period data
    INSERT INTO #PlayerProductSummary (
        CustId, AffId, GroupId, GroupProductId, ProductId, 
        ActiveQualifiedDate, TotalDeposit, Turnover, BetTickets, FDM
    )
    SELECT
        COALESCE(t.CustId, d.CustId, f.CustId) AS CustId,
        COALESCE(t.AffId, d.AffId, f.AffId) AS AffId,
        COALESCE(t.GroupId, d.GroupId, f.GroupId) AS GroupId,
        COALESCE(t.GroupProductId, d.GroupProductId, f.GroupProductId) AS GroupProductId,
        COALESCE(t.ProductId, d.ProductId, f.ProductId) AS ProductId,
        COALESCE(t.ActiveQualifiedDate, d.ActiveQualifiedDate, f.ActiveQualifiedDate) AS ActiveQualifiedDate,
        ISNULL(d.TotalDeposit, 0) AS TotalDeposit,
        ISNULL(t.Turnover, 0) AS Turnover,
        ISNULL(t.BetTickets, 0) AS BetTickets,
        ISNULL(f.FDM, 0) AS FDM
    FROM TO_Summary_OldActive t
    FULL JOIN Deposit_Summary_OldActive d 
        ON t.CustId = d.CustId 
        AND t.AffId = d.AffId 
        AND t.GroupId = d.GroupId 
        AND t.ActiveQualifiedDate = d.ActiveQualifiedDate
    FULL JOIN FDM_Summary_OldActive f 
        ON COALESCE(t.CustId, d.CustId) = f.CustId 
        AND COALESCE(t.AffId, d.AffId) = f.AffId 
        AND COALESCE(t.GroupId, d.GroupId) = f.GroupId 
        AND COALESCE(t.ActiveQualifiedDate, d.ActiveQualifiedDate) = f.ActiveQualifiedDate;

    -- 8. Compare with #DealSetting to find the correct tier for each product and condition
    CREATE TABLE #PlayerProductQualification (
        CustId INT,
        AffId INT,
        GroupId INT,
        GroupProductId INT,
        ProductId INT,
        TierId INT,
        MaxTier INT,
        CPAAmount MONEY,
        TotalDeposit MONEY,
        Turnover MONEY,
        BetTickets INT,
        FDM MONEY,
        ActiveQualifiedDate DATE,
		DeadlineActiveQDate DATE,
		FirstDepositDate DATE,
		ExpiredRedepositDate DATE,
		IsRedeposit BIT DEFAULT 0
    );
    -- 8a. Populate #PlayerProductQualification with player, affiliate, and deal info
    INSERT INTO #PlayerProductQualification (CustId, AffId, GroupId, GroupProductId, ProductId, TierId, MaxTier, CPAAmount, FirstDepositDate, ExpiredRedepositDate, TotalDeposit, Turnover, BetTickets, FDM, ActiveQualifiedDate, DeadlineActiveQDate)
    SELECT
        pps.CustId,
        pps.AffId,
        ds.GroupId,
        ds.GroupProductId,
        0 , --pps.ProductId,
        ds.TierId,
        ds.MaxTier,
        ds.CPAAmount,
        pd.FirstDepositDate,
        pd.ExpiredRedepositDate,
        pps.TotalDeposit,
        pps.Turnover,
        pps.BetTickets,
        CASE WHEN ds.MinFDM IS NOT NULL THEN pps.FDM ELSE 0 END AS FDM, -- Only populate FDM if have setting FDM
        CASE WHEN (ds.TierId = ds.MaxTier AND ds.ModeDeal = 2) OR ds.ModeDeal = 1 THEN pps.ActiveQualifiedDate ELSE pd.DeadlineActiveQDate END AS ActiveQualifiedDate,
		pd.DeadlineActiveQDate
    FROM ( 
			SELECT pps.CustId,
				pps.AffId,
				MAX (pps.FDM) as FDM,
				pps.GroupId,
				pps.GroupProductId,
				MAX (pps.TotalDeposit) AS TotalDeposit,
				SUM (pps.Turnover) AS Turnover,
				SUM (pps.BetTickets) AS BetTickets,
				pps.ActiveQualifiedDate
			FROM #PlayerProductSummary pps  
			GROUP BY CustId, AffId, GroupProductId, GroupId, ActiveQualifiedDate
    ) pps
    CROSS APPLY (
					SELECT TOP 1 ds2.GroupId, ds2.GroupProductId, ds2.TierId, ds2.CPAAmount, ds2.MaxTier, ds2.ModeDeal, ds2.MinFDM
					FROM #DealSetting ds2
					WHERE ds2.GroupId = pps.GroupId 
						AND (ds2.GroupProductId = pps.GroupProductId OR pps.GroupProductId = -1)
						AND ((ds2.MinFDM IS NULL) OR (ds2.MinFDM IS NOT NULL AND pps.FDM >= ds2.MinFDM))
						AND ((ds2.MinTotalDeposit IS NULL) OR (ds2.MinTotalDeposit IS NOT NULL AND pps.TotalDeposit >= ds2.MinTotalDeposit))
						AND ((ds2.MinTO IS NULL) OR (ds2.MinTO IS NOT NULL AND pps.Turnover >= ds2.MinTO))
					ORDER BY ds2.TierId DESC -- Then by highest TierId
    ) ds
    INNER JOIN #PlayerDeal pd ON pps.CustId = pd.CustId

    -- 9. Keep only the row with the maximum TierId for each (GroupId, GroupProductId) for MinTotalDeposit, MinTO conditions

    DELETE c
    FROM #PlayerProductQualification c
    WHERE c.TierId < c.MaxTier
        AND EXISTS(
					SELECT TOP 1 1
					FROM #DealSetting ds
					WHERE ds.GroupId = c.GroupId
					  AND (ds.GroupProductId = c.GroupProductId OR c.GroupProductId = -1)
					  AND ds.ModeDeal = 2 -- 2: Other(TO or TotalDeposit Setting)
        )
	    AND DATEADD(DAY, 1, @CPADate) < c.DeadlineActiveQDate;  -- Only consider rows with ActiveQualifiedDate before deadlineActiveQDate

    -- 9a. Get Redeposit qualification
    UPDATE pq SET pq.IsRedeposit = 1
    FROM #PlayerProductQualification pq
    INNER JOIN #PlayerDeal pd ON pq.CustId = pd.CustId AND pd.ExpiredRedepositDate IS NOT NULL
    CROSS APPLY (
					SELECT SUM(d.Deposit * ISNULL(exr.Rate, 1)) AS DepositAmount
					FROM dbo.rptMemberDaily d WITH (NOLOCK)
					LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON pd.Currency = t.TpExchangeId
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(d.WinlostDate, ISNULL(t.ExchangeId, pd.Currency), @BaseCurrency) exr
					WHERE d.CustId = pq.CustId
						AND d.WinlostDate BETWEEN pd.FirstDepositDate AND IIF(@CPADate < pd.ExpiredRedepositDate, @CPADate, pd.ExpiredRedepositDate)
						AND d.ProductId = -1
					HAVING SUM(d.Deposit * ISNULL(exr.Rate, 1)) > pd.FDM
    ) AS calc         

     -- 11a. Delete MemberCPA rows 
    CREATE TABLE #DeletedMemberCPA (MemberCPA_ID INT, CUSTID INT);

    -- 11a.1. Delete MemberCPA rows that do not exist in the source and collect deleted keys
    DELETE mc
    OUTPUT DELETED.MemberCPA_ID, DELETED.CustId INTO #DeletedMemberCPA(MemberCPA_ID, CUSTID)
    FROM MemberCPA mc WITH (ROWLOCK)
    WHERE mc.StatusId NOT IN (3,4,5,6)
      AND NOT EXISTS (
          SELECT TOP 1 1
          FROM #PlayerProductQualification pq
          WHERE pq.CustId = mc.CustId
      )
      AND EXISTS ( 
            SELECT TOP 1 1 
            FROM #PlayerDeal pd
            WHERE pd.CustId = mc.CustId
    );

    -- 11a.2. Delete MemberCPA rows that do not exist in the setting because of change group deal, just the same AffID and CustID but different GroupId
    DELETE mc
    OUTPUT DELETED.MemberCPA_ID, DELETED.CustId INTO #DeletedMemberCPA (MemberCPA_ID, CUSTID)
    FROM MemberCPA mc WITH (ROWLOCK) 
	INNER JOIN AffInfo ai WITH (NOLOCK)  ON ai.AffId =  mc.AffId AND ai.GroupId <> mc.GroupId
    WHERE mc.StatusId NOT IN (3,4,5,6)
    

    -- 11a.3. Delete MemberCPA rows that do not exist target country
    DELETE mc
    OUTPUT DELETED.MemberCPA_ID, DELETED.CustId INTO #DeletedMemberCPA (MemberCPA_ID, CUSTID)
    FROM MemberCPA mc WITH (ROWLOCK) 
    WHERE mc.StatusId NOT IN (3,4,5,6)
        AND NOT EXISTS (
            SELECT 1
            FROM #GroupCurrency gc
            INNER JOIN MemberInfo mi WITH (NOLOCK) ON gc.CurrencyID = mi.Currency
            WHERE mi.CustId = mc.CustId
            AND gc.GroupId = mc.GroupId
            AND mi.IsRemoved = 0
            AND mi.Status = 1
        );

    -- 11a.4. Find MemberCPA rows that do not have TO setting anymore, to delete them on detail tables
    SELECT DISTINCT mc.MemberCPA_ID
    INTO #MemberCPAWithoutTO
    FROM MemberCPA mc WITH (ROWLOCK)    
    WHERE EXISTS (
        SELECT 1
        FROM #DealSetting ds
        WHERE ds.GroupId = mc.GroupId
          AND (ds.MinTO IS NULL)
        )
        AND EXISTS (SELECT 1 FROM #PlayerDeal pd WHERE pd.CustId = mc.CustId)


    -- 11a.5. Delete related MemberCPATier rows using deleted MemberCPA_IDs
    DELETE mct
    FROM MemberCPATier mct WITH (ROWLOCK)
    WHERE EXISTS (SELECT 1 FROM #DeletedMemberCPA dmp WHERE dmp.MemberCPA_ID = mct.MemberCPA_ID)
		OR EXISTS (SELECT 1 FROM #MemberCPAWithoutTO mcw WHERE mcw.MemberCPA_ID = mct.MemberCPA_ID);

    -- 11a.6. Delete related MemberCPAProduct rows using deleted MemberCPA_IDs only
    DELETE mcp
    FROM MemberCPAProduct mcp WITH (ROWLOCK)
    WHERE EXISTS (SELECT 1 FROM #DeletedMemberCPA dmp WHERE dmp.MemberCPA_ID = mcp.MemberCPA_ID)
		OR EXISTS (SELECT 1 FROM #MemberCPAWithoutTO mcw WHERE mcw.MemberCPA_ID = mcp.MemberCPA_ID);


    -- Create indexes on #PlayerProductQualification for better performance
    CREATE CLUSTERED INDEX IX_PlayerProductQualification_GroupId_CustId ON #PlayerProductQualification (GroupId, CustId);
       
    -- 10. Upsert (MERGE) into MemberCPA (main CPA qualification table)
    MERGE MemberCPA AS target
    USING (
            SELECT
                CustId,
                AffId,
                GroupId,
                FirstDepositDate,
                ExpiredRedepositDate,
                IsRedeposit,
                MAX(FDM)            AS FDM,
                MAX(ActiveQualifiedDate) AS ActiveQualifiedDate,
                MAX(TotalDeposit)   AS TotalDeposit,
                SUM(Turnover)       AS Turnover,
                SUM(BetTickets)     AS BetTickets,
                SUM(CPAAmount)      AS CPAAmount
            FROM #PlayerProductQualification
            GROUP BY
                CustId,
                AffId,
                GroupId,
                FirstDepositDate,
                ExpiredRedepositDate,
                IsRedeposit 
            ) AS source
    ON target.CustId = source.CustId
    WHEN MATCHED AND target.StatusId NOT IN (3,4,5,6) THEN
        UPDATE SET
            target.TotalDeposit = source.TotalDeposit,
            target.Turnover = source.Turnover,
            target.BetTickets = source.BetTickets,
            target.FDM = source.FDM,
            target.CPAAmount = source.CPAAmount, -- Add CPAAmount to update
            target.StatusId = 0,
            target.FirstDepositDate = source.FirstDepositDate,
            target.ExpiredRedepositDate = source.ExpiredRedepositDate,
            target.IsRedeposit = source.IsRedeposit,
            target.UpdatedDate = DATEADD(HOUR, 8, GETUTCDATE()),
            target.ActiveQualifiedDate = source.ActiveQualifiedDate
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (AffId, CustId, GroupId, ActiveQualifiedDate, TotalDeposit, Turnover, BetTickets, FDM, CPAAmount, StatusId, FirstDepositDate, ExpiredRedepositDate, IsRedeposit, UpdatedDate)
        VALUES (source.AffId, source.CustId, source.GroupId, source.ActiveQualifiedDate, source.TotalDeposit, source.Turnover, source.BetTickets, source.FDM, source.CPAAmount, 0, source.FirstDepositDate, source.ExpiredRedepositDate, source.IsRedeposit, DATEADD(HOUR, 8, GETUTCDATE()));

    -- 12a. Insert players who have exceeded ActiveDays and HoldingDays but did not qualify into MemberCPA_EOL
    INSERT INTO MemberCPA_EOL (CustId, AffId, GroupId, ActiveExpiredDate, FDM, TotalDeposit, Turnover, BetTickets, HoldingExpiredDate, CreatedDate)
    SELECT
        pd.CustId,
        pd.AffId,
        pd.GroupId,
        CONVERT(DATE, DATEADD(DAY, pd.ActiveDays - 1, pd.RegisteredDate)) AS ActiveQualifiedDate,
        pd.FDM,
        MAX(ISNULL(pps.TotalDeposit, 0)) AS TotalDeposit,
        SUM(ISNULL(pps.Turnover, 0)) AS Turnover,
        SUM(ISNULL(pps.BetTickets, 0)) AS BetTickets,
        CONVERT(DATE, DATEADD(DAY, pd.ActiveDays + pd.HoldingDays - 1, pd.RegisteredDate)) AS HoldingQualifiedDate,
        DATEADD(HOUR, 8, GETUTCDATE()) AS CreatedDate -- Use GMT+8
    FROM #PlayerDeal pd
		INNER JOIN #PlayerProductSummary pps ON pd.CustId = pps.CustId AND pd.AffId = pps.AffId AND pd.GroupId = pps.GroupId
    WHERE NOT EXISTS (SELECT 1 FROM MemberCPA mc WITH (NOLOCK) WHERE mc.CustId = pd.CustId)
      AND NOT EXISTS (SELECT 1 FROM MemberCPA_EOL eol WITH (NOLOCK) WHERE eol.CustId = pd.CustId)
      AND CONVERT(DATE, pd.RegisteredDate) = DATEADD(DAY, (1 - pd.ActiveDays - pd.HoldingDays), @CPADate)
    GROUP BY pd.CustId, pd.AffId, pd.GroupId, pd.ActiveDays, pd.HoldingDays, pd.RegisteredDate, pd.FDM;

      
    -- 13a. Upsert (MERGE) into MemberCPATier
    -- Pre-calculate MemberCPATier data to improve performance
    DECLARE @MemberCPATierData TABLE (
        MemberCPA_ID INT,
        AffId INT,
        CustId INT, 
        GroupId INT,
        GroupProductId INT,
        ActiveQualifiedDate DATE,
        Turnover MONEY,
        BetTickets INT,
        CPAAmount MONEY,
        UpdatedDate DATETIME
    );
    
    INSERT INTO @MemberCPATierData (MemberCPA_ID, AffId, CustId, GroupId, GroupProductId, ActiveQualifiedDate, Turnover, BetTickets, CPAAmount, UpdatedDate)
    SELECT
        mc.MemberCPA_ID,
        pq.AffId,
        pq.CustId,
        pq.GroupId,
        pq.GroupProductId,
        pq.ActiveQualifiedDate,
        SUM(pq.Turnover) AS Turnover,
        SUM(pq.BetTickets) AS BetTickets,
        SUM(pq.CPAAmount) AS CPAAmount,
        DATEADD(HOUR, 8, GETUTCDATE()) AS UpdatedDate
    FROM MemberCPA mc WITH (NOLOCK)
    INNER JOIN #PlayerProductQualification pq
        ON mc.CustId = pq.CustId
        AND mc.AffId = pq.AffId
        AND mc.GroupId = pq.GroupId    
    WHERE pq.Turnover <> 0 OR pq.BetTickets <> 0
    GROUP BY mc.MemberCPA_ID, pq.AffId, pq.CustId, pq.GroupId, pq.GroupProductId, pq.ActiveQualifiedDate;
  
    
    -- Delete MemberCPATier rows by MemberCPA_ID and Insert new
    DELETE mct
	FROM MemberCPATier mct WITH (ROWLOCK)
    WHERE EXISTS (SELECT 1 FROM @MemberCPATierData mcd WhERE mcd.MemberCPA_ID = mct.MemberCPA_ID);

    INSERT INTO MemberCPATier (MemberCPA_ID, AffId, CustId, GroupId, GroupProductId, ActiveQualifiedDate, Turnover, BetTickets, CPAAmount, UpdatedDate)
    SELECT
        MemberCPA_ID,
        AffId,
        CustId,
        GroupId,
        GroupProductId,
        ActiveQualifiedDate,
        Turnover,
        BetTickets,
        CPAAmount,
        UpdatedDate
    FROM @MemberCPATierData;

    -- 14a. Upsert (MERGE) into MemberCPAProduct
    -- Pre-calculate MemberCPAProduct data to improve performance
    DECLARE @MemberCPAProductData TABLE (
        MemberCPATier_ID INT,
        MemberCPA_ID INT,
        AffId INT,
        CustId INT,
        GroupId INT,
        GroupProductId INT,
        ProductId INT,
        ActiveQualifiedDate DATE,
        Turnover MONEY,
        BetTickets INT,
        UpdatedDate DATETIME
    );
    
    INSERT INTO @MemberCPAProductData (
        MemberCPATier_ID, MemberCPA_ID, AffId, CustId, GroupId, GroupProductId, 
        ProductId, ActiveQualifiedDate, Turnover, BetTickets, UpdatedDate
    )
    SELECT
        tier.MemberCPATier_ID,
        tier.MemberCPA_ID,
        pq.AffId,
        pq.CustId,
        pq.GroupId,
        pq.GroupProductId,
        pq.ProductId,            
        tier.ActiveQualifiedDate,
        SUM(pq.Turnover) AS Turnover,
        SUM(pq.BetTickets) AS BetTickets,
        DATEADD(HOUR, 8, GETUTCDATE()) AS UpdatedDate
    FROM MemberCPATier tier WITH (NOLOCK)
    INNER JOIN MemberCPA mc WITH (NOLOCK) ON tier.MemberCPA_ID = mc.MemberCPA_ID
    INNER JOIN #PlayerProductSummary pq
        ON mc.AffId = pq.AffId 
        AND mc.CustId = pq.CustId 
        AND mc.GroupId = pq.GroupId 
        AND tier.GroupProductId = pq.GroupProductId            
    GROUP BY tier.MemberCPATier_ID, tier.MemberCPA_ID, pq.AffId, pq.CustId, pq.GroupId, pq.GroupProductId, pq.ProductId, tier.ActiveQualifiedDate;
       
    -- Delete MemberCPAProduct rows by MemberCPA_ID and Insert new
    DELETE mcp
	FROM MemberCPAProduct mcp WITH (ROWLOCK)
    WHERE EXISTS (SELECT 1 FROM @MemberCPAProductData m WHERE m.MemberCPA_ID = mcp.MemberCPA_ID); 

    INSERT INTO MemberCPAProduct (MemberCPATier_ID, MemberCPA_ID, AffId, CustId, GroupId, GroupProductId, ProductId, Turnover, ActiveQualifiedDate, BetTickets, UpdatedDate)
    SELECT
        MemberCPATier_ID,
        MemberCPA_ID,
        AffId,
        CustId,
        GroupId,
        GroupProductId,
        ProductId,
        Turnover,
        ActiveQualifiedDate,
        BetTickets,
        UpdatedDate
    FROM @MemberCPAProductData;
    ---------------------------------------------------------------------------------------
    -------------------------------Session for new Player---------------------------------

    -- 5b. Populate #PlayerDeal with new player, affiliate, and deal info  
    DELETE #PlayerDeal WHERE OldActiveQDate IS NOT NULL -- Clear previous entries with OldActiveQDate

    INSERT INTO #PlayerDeal (CustId, AffId, GroupId, ActiveDays, HoldingDays, RegisteredDate, FDM, FirstDepositDate, ExpiredRedepositDate, Currency, rptFromDate, rptToDate, OldActiveQDate, DeadlineActiveQDate)
    SELECT
        mi.CustId,
        mi.AffId,
        ai.GroupId,
        gc.ActiveDays,         -- Use ActiveDays from #GroupCurrency
        gc.HoldingDays,        -- Use HoldingDays from #GroupCurrency
        mi.RegisteredDate,       
        ISNULL(mi.FirstDepositAmount, 0) * ISNULL(exr.Rate, 1) AS FDM, -- Convert FDM to base currency, handle null
        mi.FirstDepositDate,
        CASE WHEN ISNULL(gc.RedepositDays, 0) = 0 THEN NULL ELSE CONVERT(DATE, DATEADD(DAY, gc.RedepositDays - 1, mi.FirstDepositDate)) END AS ExpiredRedepositDate,
        mi.Currency,
        mi.RegisteredDate AS rptFromDate,
        CASE WHEN CONVERT(DATE, DATEADD(DAY, gc.ActiveDays - 1, mi.RegisteredDate)) < @CPADate
                THEN CONVERT(DATE, DATEADD(DAY, gc.ActiveDays , mi.RegisteredDate))  --   Ensure rptToDate is inclusive of the last day
                ELSE DATEADD(DAY, 1, @CPADate) --   Ensure rptToDate is inclusive of the last day
            END 
        AS rptToDate,
        NULL AS OldActiveQDate, -- not from MemberCPA
        CONVERT(DATE, DATEADD(DAY, gc.ActiveDays, mi.RegisteredDate)) AS DeadlineActiveQDate -- renamed
    FROM AffGroupHistory ai WITH (NOLOCK)
    INNER JOIN #GroupCurrency gc ON  gc.GroupId = ai.GroupId
    INNER JOIN MemberInfo mi WITH (NOLOCK) ON gc.CurrencyID = mi.Currency AND ai.AffId = mi.AffId  
    LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
    CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(mi.FirstDepositDate, ISNULL(t.ExchangeId, mi.Currency), @BaseCurrency) exr
    WHERE mi.RegisteredDate >= DATEADD(DAY, (1 - gc.ActiveDays - gc.HoldingDays), @CPADate)
      AND mi.RegisteredDate  < DATEADD(DAY, 1, @CPADate)
      AND mi.Status = 1
      AND mi.IsRemoved = 0
      AND mi.RegisteredDate >= gc.StartDate
      AND ai.ToDate = @Todate
      AND EXISTS (SELECT TOP 1 1 FROM AffInfo af WITH (NOLOCK) WHERE af.AffId = mi.AffId AND af.IsClosed <> 1 AND af.Status = 'Approved' AND af.IsRejected <> 1)
      AND NOT EXISTS (SELECT TOP 1 1 FROM MemberCPA_EOL eol WITH (NOLOCK) WHERE eol.CustId = mi.CustId) -- Exclude CustId already in MemberCPA_EOL
      AND NOT EXISTS (SELECT TOP 1 1 FROM MemberCPA mc WITH (NOLOCK) WHERE mc.CustId = mi.CustId) -- Exclude CustId already in MemberCPA
      AND NOT EXISTS (SELECT TOP 1 1 FROM #PlayerDeal d WITH (NOLOCK) WHERE d.CustId = mi.CustId) -- Exclude CustId already deleted from #PlayerDeal
   ;
     
    -- 7b. Summarize player activity for CPA qualification based on tier settings
    TRUNCATE TABLE #PlayerProductSummary;

    -- Current period summaries
    WITH TO_Summary AS (
        SELECT
            pd.CustId,
            pd.AffId,
            pd.GroupId,
            cps.GroupProductId,
            cps.ProductId,
            pd.rptToDate AS ActiveQualifiedDate,
            SUM(rd.Turnover * ISNULL(exr.Rate, 1)) AS Turnover,
            SUM(rd.BetCount) AS BetTickets
        FROM #PlayerDeal pd
        INNER JOIN CPAProductSetting cps WITH (NOLOCK) ON pd.GroupId = cps.GroupId AND cps.ToDate = @Todate
        INNER JOIN rptMemberDaily rd WITH (NOLOCK) ON pd.CustId = rd.CustId AND rd.ProductId = cps.ProductId
        LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON pd.Currency = t.TpExchangeId
        CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(rd.WinlostDate, ISNULL(t.ExchangeId, pd.Currency), @BaseCurrency) exr
        WHERE rd.WinlostDate >= pd.rptFromDate
          AND rd.WinlostDate < pd.rptToDate
        GROUP BY pd.CustId, pd.AffId, pd.GroupId, cps.GroupProductId, cps.ProductId, pd.rptToDate
    ),
    Deposit_Summary AS (
        SELECT
            pd.CustId,
            pd.AffId,
            pd.GroupId,
            -1 AS GroupProductId,
            -1 AS ProductId,
            pd.rptToDate AS ActiveQualifiedDate,
            SUM(rd.Deposit * ISNULL(exr.Rate, 1)) AS TotalDeposit
        FROM #PlayerDeal pd
        INNER JOIN rptMemberDaily rd WITH (NOLOCK) ON pd.CustId = rd.CustId
        CROSS APPLY (
            SELECT TOP 1 1 AS HasMinTotalDeposit
            FROM #DealSetting ds2
            WHERE ds2.GroupId = pd.GroupId AND ds2.MinTotalDeposit IS NOT NULL
        ) checkMinTotalDeposit
        LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON pd.Currency = t.TpExchangeId
        CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(rd.WinlostDate, ISNULL(t.ExchangeId, pd.Currency), @BaseCurrency) exr
        WHERE rd.WinlostDate >= pd.rptFromDate
          AND rd.WinlostDate < pd.rptToDate
          AND rd.ProductId = -1
        GROUP BY pd.CustId, pd.AffId, pd.GroupId, pd.rptToDate
    ),
    FDM_Summary AS (
        SELECT
            pd.CustId,
            pd.AffId,
            pd.GroupId,
            -1 AS GroupProductId,
            -1 AS ProductId,
            pd.rptToDate AS ActiveQualifiedDate,
            pd.FDM
        FROM #PlayerDeal pd
        CROSS APPLY (
            SELECT TOP 1 1 AS HasMinFDM
            FROM #DealSetting ds2
            WHERE ds2.GroupId = pd.GroupId AND ds2.MinFDM IS NOT NULL
        ) checkMinFDM
        WHERE pd.FirstDepositDate >= pd.rptFromDate
          AND pd.FirstDepositDate < pd.rptToDate
        GROUP BY pd.CustId, pd.AffId, pd.GroupId, pd.FDM, pd.rptToDate
    )
    -- Insert current period data
    INSERT INTO #PlayerProductSummary (
        CustId, AffId, GroupId, GroupProductId, ProductId, 
        ActiveQualifiedDate, TotalDeposit, Turnover, BetTickets, FDM
    )
    SELECT
        COALESCE(t.CustId, d.CustId, f.CustId) AS CustId,
        COALESCE(t.AffId, d.AffId, f.AffId) AS AffId,
        COALESCE(t.GroupId, d.GroupId, f.GroupId) AS GroupId,
        COALESCE(t.GroupProductId, d.GroupProductId, f.GroupProductId) AS GroupProductId,
        COALESCE(t.ProductId, d.ProductId, f.ProductId) AS ProductId,
        COALESCE(t.ActiveQualifiedDate, d.ActiveQualifiedDate, f.ActiveQualifiedDate) AS ActiveQualifiedDate,
        ISNULL(d.TotalDeposit, 0) AS TotalDeposit,
        ISNULL(t.Turnover, 0) AS Turnover,
        ISNULL(t.BetTickets, 0) AS BetTickets,
        ISNULL(f.FDM, 0) AS FDM
    FROM TO_Summary t
    FULL JOIN Deposit_Summary d 
        ON t.CustId = d.CustId 
        AND t.AffId = d.AffId 
        AND t.GroupId = d.GroupId 
        AND t.ActiveQualifiedDate = d.ActiveQualifiedDate
    FULL JOIN FDM_Summary f 
        ON COALESCE(t.CustId, d.CustId) = f.CustId 
        AND COALESCE(t.AffId, d.AffId) = f.AffId 
        AND COALESCE(t.GroupId, d.GroupId) = f.GroupId 
        AND COALESCE(t.ActiveQualifiedDate, d.ActiveQualifiedDate) = f.ActiveQualifiedDate;

    -- 8b. Compare with #DealSetting to find the correct tier for each product and condition  
    TRUNCATE TABLE #PlayerProductQualification;

    INSERT INTO #PlayerProductQualification (CustId, AffId, GroupId, GroupProductId, ProductId, TierId, MaxTier, CPAAmount, FirstDepositDate, ExpiredRedepositDate, TotalDeposit, Turnover, BetTickets, FDM, ActiveQualifiedDate, DeadlineActiveQDate)
    SELECT
        pps.CustId,
        pps.AffId,
        ds.GroupId,
        ds.GroupProductId,
        0 , --pps.ProductId,
        ds.TierId,
		ds.MaxTier,
        ds.CPAAmount,
        pd.FirstDepositDate,
        pd.ExpiredRedepositDate,
        pps.TotalDeposit,
        pps.Turnover,
        pps.BetTickets,
        CASE WHEN ds.MinFDM IS NOT NULL THEN pps.FDM ELSE 0 END AS FDM, -- Only populate FDM if have setting FDM
        CASE WHEN (ds.TierId = ds.MaxTier AND ds.ModeDeal = 2) OR ds.ModeDeal = 1 THEN pps.ActiveQualifiedDate ELSE pd.DeadlineActiveQDate END AS ActiveQualifiedDate,
		pd.DeadlineActiveQDate
    FROM ( 
        SELECT pps.CustId,
            pps.AffId,
            MAX (pps.FDM) AS FDM,
            pps.GroupId,
            pps.GroupProductId,
            MAX (pps.TotalDeposit) AS TotalDeposit,
            SUM (pps.Turnover) AS Turnover,
            SUM (pps.BetTickets) AS BetTickets,
            pps.ActiveQualifiedDate           
        FROM #PlayerProductSummary pps  
        GROUP BY CustId, AffId, GroupProductId, GroupId, ActiveQualifiedDate
    ) pps
    CROSS APPLY(
        SELECT TOP 1 ds2.GroupId, ds2.GroupProductId, ds2.TierId, ds2.CPAAmount, ds2.MaxTier, ds2.ModeDeal, ds2.MinFDM
        FROM #DealSetting ds2
        WHERE ds2.GroupId = pps.GroupId 
            AND (ds2.GroupProductId = pps.GroupProductId OR pps.GroupProductId = -1)
            AND ((ds2.MinFDM IS NULL) OR (ds2.MinFDM IS NOT NULL AND pps.FDM >= ds2.MinFDM))
            AND ((ds2.MinTotalDeposit IS NULL) OR (ds2.MinTotalDeposit IS NOT NULL AND pps.TotalDeposit >= ds2.MinTotalDeposit))
            AND ((ds2.MinTO IS NULL) OR (ds2.MinTO IS NOT NULL AND pps.Turnover >= ds2.MinTO))
        ORDER BY ds2.TierId DESC -- Then by highest TierId
    ) ds
    INNER JOIN #PlayerDeal pd ON pps.CustId = pd.CustId;

    -- 9b. Keep only the row with the maximum TierId for each (GroupId, GroupProductId) for MinTotalDeposit, MinTO conditions
    DELETE c
    FROM #PlayerProductQualification c
    INNER JOIN #PlayerDeal mi ON c.CustId = mi.CustId
    WHERE c.TierId < c.MaxTier
        AND EXISTS(
            SELECT TOP 1 1
            FROM #DealSetting ds
            WHERE ds.GroupId = c.GroupId
              AND (ds.GroupProductId = c.GroupProductId OR c.GroupProductId = -1)
              AND ds.ModeDeal = 2 -- 2: Other(TO or TotalDeposit Setting)
        )
        AND DATEADD(DAY, 1, @CPADate) < c.DeadlineActiveQDate; -- Only consider rows with ActiveQualifiedDate before deadlineActiveQDate

    -- 9c. Get Redeposit qualification

    UPDATE pq SET pq.IsRedeposit = 1
    FROM #PlayerProductQualification pq
    INNER JOIN #PlayerDeal pd ON pq.CustId = pd.CustId AND pd.ExpiredRedepositDate IS NOT NULL
    CROSS APPLY (
                    SELECT SUM(d.Deposit * ISNULL(exr.Rate, 1)) AS DepositAmount
                    FROM dbo.rptMemberDaily d WITH (NOLOCK)
                    LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON pd.Currency = t.TpExchangeId
                    CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(d.WinlostDate, ISNULL(t.ExchangeId, pd.Currency), @BaseCurrency) exr
                    WHERE d.CustId = pq.CustId
						AND d.WinlostDate BETWEEN pd.FirstDepositDate AND IIF(@CPADate < pd.ExpiredRedepositDate, @CPADate, pd.ExpiredRedepositDate)
                        AND d.ProductId = -1
                    HAVING SUM(d.Deposit * ISNULL(exr.Rate, 1)) > pd.FDM
    ) AS calc 

    -- 10b. INSERT into MemberCPA (main CPA qualification table)
    -- Pre-calculate aggregated CPA data once to improve performance

    INSERT INTO MemberCPA (AffId, CustId, GroupId, ActiveQualifiedDate, TotalDeposit, Turnover, BetTickets, FDM, CPAAmount, StatusId, FirstDepositDate, ExpiredRedepositDate, IsRedeposit, UpdatedDate)
    SELECT  source.AffId, source.CustId, source.GroupId, MAX(source.ActiveQualifiedDate), 
            MAX(source.TotalDeposit), SUM(source.Turnover), SUM(source.BetTickets), MAX(source.FDM), SUM(source.CPAAmount),
            0 AS StatusId, source.FirstDepositDate, source.ExpiredRedepositDate, source.IsRedeposit, DATEADD(HOUR, 8, GETUTCDATE()) AS UpdatedDate 
    FROM #PlayerProductQualification source
    GROUP BY source.AffId, source.CustId, source.GroupId, source.FirstDepositDate, source.ExpiredRedepositDate, source.IsRedeposit;

    -- 12b. Insert players who have exceeded ActiveDays and HoldingDays but did not qualify into MemberCPA_EOL
    INSERT INTO MemberCPA_EOL (CustId, AffId, GroupId, ActiveExpiredDate, FDM, TotalDeposit, Turnover, BetTickets, HoldingExpiredDate, CreatedDate)
    SELECT
        pd.CustId,
        pd.AffId,
        pd.GroupId,
        CONVERT(DATE, DATEADD(DAY, pd.ActiveDays - 1, pd.RegisteredDate)) AS ActiveQualifiedDate,
        pd.FDM,
        MAX(ISNULL(pps.TotalDeposit, 0)) AS TotalDeposit,
        SUM(ISNULL(pps.Turnover, 0)) AS Turnover,
        SUM(ISNULL(pps.BetTickets, 0)) AS BetTickets,
        CONVERT(DATE, DATEADD(DAY, pd.ActiveDays + pd.HoldingDays - 1, pd.RegisteredDate)) AS HoldingQualifiedDate,
        DATEADD(HOUR, 8, GETUTCDATE()) AS CreatedDate -- Use GMT+8
    FROM #PlayerDeal pd
        INNER JOIN #PlayerProductSummary pps ON pd.CustId = pps.CustId AND pd.AffId = pps.AffId AND pd.GroupId = pps.GroupId
    WHERE NOT EXISTS (SELECT 1 FROM MemberCPA mc WITH (NOLOCK) WHERE mc.CustId = pd.CustId)
      AND NOT EXISTS (SELECT 1 FROM MemberCPA_EOL eol WITH (NOLOCK) WHERE eol.CustId = pd.CustId)
      AND CONVERT(DATE, pd.RegisteredDate) = DATEADD(DAY, (1 - pd.ActiveDays - pd.HoldingDays), @CPADate)
    GROUP BY pd.CustId, pd.AffId, pd.GroupId, pd.ActiveDays, pd.HoldingDays, pd.RegisteredDate, pd.FDM;
      
    -- 13b. Upsert (MERGE) into MemberCPATier
    INSERT INTO MemberCPATier (MemberCPA_ID, AffId, CustId, GroupId, GroupProductId, ActiveQualifiedDate, Turnover, BetTickets, CPAAmount, UpdatedDate)
    SELECT
        mc.MemberCPA_ID,
        pq.AffId,
        pq.CustId,
        pq.GroupId,
        pq.GroupProductId,
        pq.ActiveQualifiedDate,
        SUM(pq.Turnover) AS Turnover,
        SUM(pq.BetTickets) AS BetTickets,
        SUM(pq.CPAAmount) AS CPAAmount,
        DATEADD(HOUR, 8, GETUTCDATE()) AS UpdatedDate
    FROM MemberCPA mc WITH (NOLOCK)
    INNER JOIN #PlayerProductQualification pq
        ON mc.CustId = pq.CustId
        AND mc.AffId = pq.AffId
        AND mc.GroupId = pq.GroupId
    WHERE pq.Turnover <> 0 OR pq.BetTickets <> 0
    GROUP BY mc.MemberCPA_ID, pq.AffId, pq.CustId, pq.GroupId, pq.GroupProductId, pq.ActiveQualifiedDate;
    

    -- 14b. Upsert (MERGE) into MemberCPAProduct   
    INSERT INTO MemberCPAProduct (MemberCPATier_ID, MemberCPA_ID, AffId, CustId, GroupId, GroupProductId, ProductId, Turnover, ActiveQualifiedDate, BetTickets, UpdatedDate)
    SELECT  
        tier.MemberCPATier_ID,
        tier.MemberCPA_ID,
        pq.AffId,
        pq.CustId,
        pq.GroupId,
        pq.GroupProductId,
        pq.ProductId,            
        SUM(pq.Turnover) AS Turnover,
        tier.ActiveQualifiedDate,
        SUM(pq.BetTickets) AS BetTickets,
        DATEADD(HOUR, 8, GETUTCDATE()) AS UpdatedDate
    FROM MemberCPATier tier WITH (NOLOCK)
    INNER JOIN MemberCPA mc WITH (NOLOCK) ON tier.MemberCPA_ID = mc.MemberCPA_ID
    INNER JOIN #PlayerProductSummary pq
        ON mc.AffId = pq.AffId 
        AND mc.CustId = pq.CustId 
        AND mc.GroupId = pq.GroupId 
        AND tier.GroupProductId = pq.GroupProductId            
    GROUP BY tier.MemberCPATier_ID, tier.MemberCPA_ID, pq.AffId, pq.CustId, pq.GroupId, pq.GroupProductId, pq.ProductId, tier.ActiveQualifiedDate;
    

    -- Drop temp tables to clean up
    DROP TABLE IF EXISTS #GroupCountry;
    DROP TABLE IF EXISTS #GroupCurrency;
    DROP TABLE IF EXISTS #PlayerDeal;
    DROP TABLE IF EXISTS #DealSetting;
    DROP TABLE IF EXISTS #PlayerProductSummary;
    DROP TABLE IF EXISTS #PlayerProductQualification;
    DROP TABLE IF EXISTS #DeletedMemberCPA;
    DROP TABLE IF EXISTS #MemberCPAWithoutTO;
 
    -- At the end, set success code
    SET @ErrCode = 0;
    SET @ErrMsg = NULL;
END