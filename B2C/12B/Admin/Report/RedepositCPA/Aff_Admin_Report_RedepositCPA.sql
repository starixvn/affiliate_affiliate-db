/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Report_RedepositCPA]
    @Username 	 	NVARCHAR(100) = ''
    ,@DealIds 	 	NVARCHAR(MAX) = ''
    ,@FromDate 	 	DATETIME = ''
    ,@ToDate 	 	DATETIME = ''
    ,@IsExportExcel BIT = 0
    ,@PageIndex 	INT = 1
    ,@PageSize 		INT = 20
    ,@NRows 		INT = 0 OUTPUT
AS
/*
    Created: 20250818@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task: Admin site - Rpt - Redeposit CPA

    Revisions:
        - 20250818@Lewis: Initialize SP [RedmineID: #236660]

    Parameter's Explanation:
        - @PageIndex: Page number (1-based)
        - @PageSize: Number of records per page
        - @NRows: Total number of records (OUTPUT)
        - @IsExportExcel: 1 = Return all data for Excel export, 0 = Return paged data
*/
BEGIN
    SET NOCOUNT ON;

    -- Validate Input
    DECLARE @CurrentDate DATE = DATEADD(HOUR, 8, GETUTCDATE());

    DECLARE @Deals TABLE (GroupId INT);
    INSERT INTO @Deals (GroupId)
    SELECT CAST(f.value AS INT)
    FROM string_split(@DealIds,',') f;

    -- Get data
    DROP TABLE IF EXISTS #data;

    CREATE TABLE #data
    (
        AffId                	INT
        ,AffUsername          	NVARCHAR(100)
        ,DealId              	INT
        ,DealName            	VARCHAR(100)
        --CPA Payment Details
        ,PaymentFrequency     	VARCHAR(50)
        ,StartFrom				DATE
        ,ApprovalDate			DATE
        ,RecheckDays			INT
        ,ExpiredRedepositDate	DATE
        --Redeposit Statistics
        ,ApprovedCPAPlayer 		INT
        ,RedepositRate   		DECIMAL(9,8)
        ,NumOfPlayerRedeposit   VARCHAR(100)
        ,TotalSettledCPAAmount	MONEY
        ,StatusId				TINYINT
        ,RowIdx					INT
    );

    INSERT INTO #data (
        AffId                
        ,AffUsername          
        ,DealId              
        ,DealName         
        --CPA Payment Details   
        ,PaymentFrequency     
        ,StartFrom				
        ,ApprovalDate			
        ,RecheckDays			
        ,ExpiredRedepositDate
        --Redeposit Statistics
        ,ApprovedCPAPlayer 		
        ,RedepositRate 
        ,NumOfPlayerRedeposit 
        ,TotalSettledCPAAmount
        ,StatusId
		,RowIdx
    )
    SELECT m.AffId
        , ai.UserName
        , m.GroupId
        , cg.GroupName
        --CPA Payment Details
        , s.ScheduleName
        , IIF(s.IntervalType = 'Day'
			, DATEADD(DAY, -s.IntervalValue, m.CPADate)
			, IIF(MONTH(cg.Startdate) = MONTH(DATEADD(DAY, 5, EOMONTH(m.CPADate, - s.IntervalValue - 1)))
				, cg.StartDate
				, DATEADD(DAY, 5, EOMONTH(m.CPADate, - s.IntervalValue - 1))
				)) AS StartFrom
        , m.CPADate AS SettledDay
        , cg.RedepositDays
        , DATEADD(DAY, cg.RedepositDays - 1, m.CPADate) AS ExpriedRedepositDate
        --Redeposit Statistics
        , COUNT(m.CustId) AS cnt_ApprovedCust
        , cg.RedepositRate
        , CONCAT(ISNULL(rd.cnt_rd, 0), '/', FLOOR(COUNT(m.CustId) * cg.RedepositRate))
        , SUM(m.CPAAmount) AS TotalCPAAmount
        , CASE 
                WHEN ISNULL(rd.cnt_rd, 0) < FLOOR(COUNT(m.CustId) * cg.RedepositRate) AND @CurrentDate <= DATEADD(DAY, cg.RedepositDays - 1, m.CPADate) THEN 1 -- 'Monitoring' --1st
                WHEN ISNULL(rd.cnt_rd, 0) < FLOOR(COUNT(m.CustId) * cg.RedepositRate)THEN 2 -- 'Not qualified' --2nd
                WHEN ISNULL(rd.cnt_rd, 0) >= FLOOR(COUNT(m.CustId) * cg.RedepositRate) THEN 3 -- 'Qualified' --3rd
        END AS StatusId
        , ROW_NUMBER() OVER(ORDER BY m.AffId ASC, m.GroupId ASC, m.CPADate ASC) AS RowIdx
    FROM dbo.MemberCPA m WITH (NOLOCK)
        INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON m.AffId = ai.AffId
        INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON m.GroupId = cg.GroupId AND cg.IsDeleted = 0
        INNER JOIN dbo.Schedule s WITH (NOLOCK) ON s.ScheduleId = cg.ScheduleId
        OUTER APPLY (	
                        SELECT COUNT(DISTINCT r.CustId) AS cnt_rd
                        FROM dbo.rptMemberDaily r WITH (NOLOCK)
							INNER JOIN dbo.MemberCPA m2 WITH (NOLOCK) ON r.AffId = m2.AffId AND r.CustId = m2.CustId
                        WHERE m2.AffId = m.AffId
							AND m2.GroupId = m.GroupId  
							AND m2.CPADate = m.CPADate
							AND m2.StatusId = 3
                            AND r.WinlostDate BETWEEN m.CPADate AND DATEADD(DAY, cg.RedepositDays - 1, m.CPADate) --After Aproved CPA
                            AND r.ProductId = -1
                            AND r.Deposit > 0
                    ) rd
    WHERE m.StatusId = 3 -- Approved
        AND m.CPADate BETWEEN @FromDate AND @ToDate
        AND (ISNULL(@Username, '') = '' OR ai.Username LIKE '%' + @Username + '%')
        AND EXISTS (SELECT 1 FROM @Deals d WHERE d.GroupId = m.GroupId)
		AND cg.RedepositDays > 0

    GROUP BY m.AffId, ai.UserName, m.GroupId, cg.GroupName, s.ScheduleName, s.IntervalValue , s.IntervalType, m.CPADate, cg.RedepositDays, cg.RedepositRate, ISNULL(rd.cnt_rd, 0), cg.StartDate;
   
    -- Get total row count
    SELECT @NRows = COUNT(*) FROM #data;

    -- Paging logic
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
		RowIdx
		,AffId                
        ,AffUsername          
        ,DealId              
        ,DealName         
        --CPA Payment Details   
        ,PaymentFrequency     
        ,StartFrom				
        ,ApprovalDate			
        ,RecheckDays			
        ,ExpiredRedepositDate
        --Redeposit Statistics
        ,ApprovedCPAPlayer 		
        ,RedepositRate 
        ,NumOfPlayerRedeposit 
        ,TotalSettledCPAAmount
        ,StatusId
		,CASE
			WHEN StatusId = 1 THEN 'Monitoring'
			WHEN StatusId = 2 THEN 'Not qualified'
			WHEN StatusId = 3 THEN 'Qualified'
		END AS Status
    FROM #data
    WHERE RowIdx BETWEEN @RowStart AND @RowEnd
    ORDER BY RowIdx ASC;

	--Return total
	SELECT 
        SUM(ApprovedCPAPlayer) AS ApprovedCPAPlayer
        ,SUM(TotalSettledCPAAmount) AS TotalSettledCPAAmount
    FROM #data

    DROP TABLE #data;
END;
GO