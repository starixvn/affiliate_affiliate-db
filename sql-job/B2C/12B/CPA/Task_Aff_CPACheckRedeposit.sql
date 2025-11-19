/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_Aff_CPACheckRedeposit
    @CPADate DATE,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created:      20251020@Lewis
    Task:         Check Redeposit Status for CPA Members
    DB:           DBAFF12B-Affiliate_12B
    
    Purpose:      Check and update redeposit status for qualified CPA members
                  - Check members with StatusId = 2, ExpiredRedepositDate NOT NULL, IsRedeposit = 0
                  - Validate if member has made deposits > FDM within redeposit period
                  - Update IsRedeposit flag accordingly
    
    Revisions:
        - 20251020@Lewis: Initial [RedmineID: #235601]
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
    DECLARE @BaseCurrency INT, 
            @TimeZone SMALLINT;
    
    -- Get base currency setting
    SELECT @BaseCurrency = ISNULL(t.ExchangeId, CONVERT(INT, SValue))
    FROM dbo.SystemSettings s WITH (NOLOCK)
    LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON CONVERT(INT, SValue) = t.TpExchangeId
    WHERE SName = 'AffCurrency';
    
    -- Get timezone setting
    SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
    FROM dbo.SystemSettings WITH (NOLOCK) 
    WHERE SName = 'TimeZone';
    
    -- =============================================
    -- DATA PROCESSING
    -- =============================================
    
    -- Create temp table for members to check
    CREATE TABLE #MembersToCheck (
        CustId INT,
        AffId INT,
        GroupId INT,
        FirstDepositDate DATE,
        ExpiredRedepositDate DATE,
        HoldingQualifiedDate DATE,
        FDM MONEY
    );
    
    -- Load members that need redeposit checking
    INSERT INTO #MembersToCheck (CustId, AffId, GroupId, FirstDepositDate, 
        ExpiredRedepositDate, HoldingQualifiedDate
    )
    SELECT 
        mc.CustId,
        mc.AffId,
        mc.GroupId,
        mc.FirstDepositDate,
        mc.ExpiredRedepositDate,
        mc.HoldingQualifiedDate
    FROM dbo.MemberCPA mc WITH (NOLOCK)
    WHERE mc.StatusId = 2
      AND mc.ExpiredRedepositDate IS NOT NULL
      AND mc.IsRedeposit = 0
      AND @CPADate BETWEEN mc.HoldingQualifiedDate AND mc.ExpiredRedepositDate;
    
	-- Update FDM
	UPDATE m SET m.FDM = mi.FirstDepositAmount * ISNULL(exr.Rate, 1)
	FROM #MembersToCheck m
		INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON m.CustId = mi.CustId
        LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON mi.Currency = t.TpExchangeId
        CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(mi.FirstDepositDate, ISNULL(t.ExchangeId, mi.Currency), @BaseCurrency) exr

    -- Create temp table for redeposit results
    CREATE TABLE #RedepositResults (
        CustId INT,
        HasRedeposit BIT,
        TotalRedeposit MONEY
    );
    
    -- Check redeposit status for each member
    INSERT INTO #RedepositResults (CustId, HasRedeposit, TotalRedeposit)
    SELECT
        mtc.CustId,
        CASE WHEN calc.DepositAmount > mtc.FDM THEN 1 ELSE 0 END AS HasRedeposit,
        ISNULL(calc.DepositAmount, 0) AS TotalRedeposit
    FROM #MembersToCheck mtc
    CROSS APPLY (
        SELECT SUM(d.Deposit * ISNULL(exr.Rate, 1)) AS DepositAmount
        FROM dbo.rptMemberDaily d WITH (NOLOCK)
        LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON d.Currency = t.TpExchangeId
        CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(d.WinlostDate, ISNULL(t.ExchangeId, d.Currency), @BaseCurrency) exr
        WHERE d.CustId = mtc.CustId
          AND d.WinlostDate BETWEEN mtc.FirstDepositDate AND IIF(@CPADate < mtc.ExpiredRedepositDate, @CPADate, mtc.ExpiredRedepositDate)
          AND d.ProductId = -1
          AND d.Deposit > 0
    ) AS calc;
    
    -- Update MemberCPA with redeposit status
    UPDATE mc
    SET mc.IsRedeposit = rr.HasRedeposit,
        mc.UpdatedDate = DATEADD(HOUR, ISNULL(@TimeZone, 8), GETUTCDATE())
    FROM dbo.MemberCPA mc WITH (UPDLOCK, ROWLOCK)
    INNER JOIN #RedepositResults rr ON mc.CustId = rr.CustId
    WHERE rr.HasRedeposit = 1; -- Only update members who have redeposited

    -- Success
    SET @ErrCode = 0;
    SET @ErrMsg = '';

    -- =============================================
    -- CLEANUP
    -- =============================================

    DROP TABLE IF EXISTS #MembersToCheck;
    DROP TABLE IF EXISTS #RedepositResults;

END;
GO