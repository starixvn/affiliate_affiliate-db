/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Report_PlayerCPA]
    @AffId INT,
    @CustName NVARCHAR(100) = '',
    @StatusId VARCHAR(MAX) = '',
    @GroupId INT = 0,
    @Viewby TINYINT = 1,
    @FromDate DATETIME = '',
    @ToDate DATETIME = '',
    @NRows INT = 0 OUTPUT
AS

/*
    Created: 20251029@Lewis
    DB: DBAFF12B-Affiliate_12B  
    Task: User - CPA Report - Player CPA Report

    Revisions:
        - 20251029@Lewis: Initialize SP [RedmineID: #241612]
*/

BEGIN
    SET NOCOUNT ON

        -- Input validation
        DECLARE @Status TABLE (StatusId SMALLINT)
        INSERT INTO @Status (StatusId)
        SELECT CAST(f.value AS SMALLINT)
        FROM string_split(@StatusId,',') f

        CREATE TABLE #data (
            MemberCPA_ID INT,
            AffId INT,
            CustId INT,
            CustUsername VARCHAR(100),
            RegisteredDate DATETIME,
            --Active Period
            FTD MONEY,
            IsFTD BIT,
            TotalDeposit MONEY,
            IsTotalDeposit BIT,
            IsTO BIT,
            AQD DATETIME,
            CPAAmount MONEY,
            --Holding Period
            IsHolding BIT,
            HoldingBetTickets SMALLINT,
            HoldingTickets SMALLINT,
            HQD DATETIME,
            HED DATETIME,
            EstimatedCPAAmount MONEY,
            --Redeposit Qualified Period
            FirstDepositDate DATETIME,
            ReDepositDays INT,
            ExpiredRedepositDate DATETIME,
            IsRedeposit BIT,
            --Status
            StatusId SMALLINT,
            CPAStatus VARCHAR(20),
            IsAbnormal BIT,
            Description VARCHAR(300)
        )
        INSERT INTO #data(
            MemberCPA_ID,
            AffId,
            CustId,
            CustUsername,
            RegisteredDate,
            --Active Period
            FTD,
            IsFTD,
            TotalDeposit,
            IsTotalDeposit,
            IsTO,
            AQD,
            CPAAmount,
            --Holding Period
            IsHolding,
            HoldingBetTickets,
            HoldingTickets,
            HQD,
            HED,
            EstimatedCPAAmount,
            --Redeposit Qualified Period
            FirstDepositDate,
            ReDepositDays,
            ExpiredRedepositDate,
            IsRedeposit,
            --Status
            StatusId,
            CPAStatus,
            IsAbnormal,
            Description
        )
        SELECT 
            m.MemberCPA_ID,
            m.AffId,
            m.CustId,
            mem.UserName,
            mem.RegisteredDate,
            --Active Period
            m.FDM,
            IIF(m.FDM = 0, 0, 1),
            m.TotalDeposit,
            IIF(m.TotalDeposit = 0, 0, 1),
            IIF(m.Turnover = 0, 0, 1),
            m.ActiveQualifiedDate,
            m.CPAAmount,
            --Holding Period
            IIF(m.HoldingBetTickets IS NULL, 0, 1),
            m.HoldingBetTickets,
            cg.HoldingTickets,
            m.HoldingQualifiedDate,
            m.HoldingExpiredDate,
            CASE WHEN m.StatusId IN (2,3,5,6) THEN m.CPAAmount ELSE 0 END,
            --Redeposit Qualified Period
            m.FirstDepositDate,
            cg.RedepositDays,
            m.ExpiredRedepositDate,
            m.IsRedeposit,
            --Status
            m.StatusId,
            CASE WHEN m.StatusId = 0 THEN 'Pending'
                 WHEN m.StatusId = 1 THEN 'Ineligible'
                 WHEN m.StatusId = 2 THEN 'Eligible'
                 WHEN m.StatusId = 3 THEN 'Settled'
                 WHEN m.StatusId = 4 THEN 'Rejected'
                 WHEN m.StatusId = 5 THEN 'Quota Exceeded'
                 WHEN m.StatusId = 6 THEN 'Redeposit Failed'
            END,
            IIF(m.StatusId = 4, 1, 0) AS IsAbnormal,
            m.Description
        FROM dbo.MemberCPA m WITH (NOLOCK)
            INNER JOIN dbo.MemberInfo mem WITH (NOLOCK) ON m.CustId = mem.CustId
            INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON m.GroupId = cg.GroupId AND cg.IsDeleted = 0
            INNER JOIN dbo.Schedule s WITH (NOLOCK) ON cg.ScheduleId = s.ScheduleId
        WHERE m.AffId = @AffId
            AND (ISNULL(@CustName, '') = '' OR mem.UserName LIKE '%' + @CustName + '%')
            AND EXISTS (SELECT 1 FROM @Status st WHERE st.StatusId = m.StatusId)
            AND (
                (@Viewby = 1 AND m.ActiveQualifiedDate BETWEEN @FromDate AND @ToDate)
                OR (@Viewby = 2 AND m.HoldingQualifiedDate BETWEEN @FromDate AND @ToDate)
            )
			AND (m.GroupId = @GroupId OR @GroupId = 0)

        -- Main result set
        SELECT
            d.MemberCPA_ID,
            ROW_NUMBER() OVER (ORDER BY d.AQD DESC) AS RowNum,
            d.CustUsername AS Player,
            d.RegisteredDate,
            --Active Period
            d.FTD,
            d.IsFTD,
            d.TotalDeposit,
            d.IsTotalDeposit,
            d.IsTO,
            d.AQD AS ActiveQualifiedDate,
            d.CPAAmount,
            --Holding Period
            d.IsHolding,
            IIF(d.IsHolding = 0, NULL, CONCAT(ISNULL(d.HoldingBetTickets, 0), '/', ISNULL(d.HoldingTickets, 0))) AS BetTicket,
            d.HQD AS HoldingQualifiedDate,
            IIF(d.IsHolding = 0, NULL, d.HED) AS HoldingExpiredDate,
            d.EstimatedCPAAmount,
            --Redeposit Qualified Period
            IIF(d.ExpiredRedepositDate IS NULL, NULL, d.FirstDepositDate) AS FirstDepositDate,
            IIF(d.ExpiredRedepositDate IS NULL, NULL, d.ReDepositDays) AS RecheckDays,
            d.ExpiredRedepositDate,
            d.IsRedeposit,
            d.CPAStatus,
            d.IsAbnormal,
            d.Description
        FROM #data d
        ORDER BY d.AQD DESC;

        -- Total count
        SELECT @NRows = COUNT(MemberCPA_ID) FROM #data;

        -- Summary totals
        SELECT 
            SUM(CPAAmount) AS CPAAmount,
            SUM(EstimatedCPAAmount) AS EstimatedCPAAmount
        FROM #data;

        DROP TABLE #data;

END
GO