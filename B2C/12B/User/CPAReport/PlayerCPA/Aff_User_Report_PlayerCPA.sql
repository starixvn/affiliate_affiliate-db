/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Report_PlayerCPA]
    @AffId INT,
    @CustName NVARCHAR(100) = '',
    @StatusId VARCHAR(MAX) = '',
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
            TotalDeposit MONEY,
            AQD DATETIME,
            CPAAmount MONEY,
            --Holding Period
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
            TotalDeposit,
            AQD,
            CPAAmount,
            --Holding Period
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
            m.TotalDeposit,
            m.ActiveQualifiedDate,
            m.CPAAmount,
            --Holding Period
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

        -- Main result set
        SELECT 
            ROW_NUMBER() OVER (ORDER BY d.AQD DESC) AS RowNum,
            d.CustUsername AS Player,
            d.RegisteredDate,
            --Active Period
            d.FTD,
            d.TotalDeposit,
            d.AQD AS ActiveQualifiedDate,
            d.CPAAmount,
            --Holding Period
            CONCAT(ISNULL(d.HoldingBetTickets, 0), '/', ISNULL(d.HoldingTickets, 0)) AS BetTicket,
            d.HQD AS HoldingQualifiedDate,
            d.HED AS HoldingExpiredDate,
            d.EstimatedCPAAmount,
            --Redeposit Qualified Period
            d.FirstDepositDate,
            d.ReDepositDays AS RecheckDays,
            d.ExpiredRedepositDate,
            CASE WHEN d.IsRedeposit = 1 THEN 'Yes' ELSE 'No' END AS IsRedeposit,
            d.CPAStatus
        FROM #data d
        ORDER BY d.AQD DESC;

        -- Total count
        SELECT @NRows = COUNT(MemberCPA_ID) FROM #data;

        -- Summary totals
        SELECT 
            SUM(CPAAmount) AS TotalCPAAmount,
            SUM(EstimatedCPAAmount) AS TotalEstimatedCPAAmount
        FROM #data;

        DROP TABLE #data;

END
GO