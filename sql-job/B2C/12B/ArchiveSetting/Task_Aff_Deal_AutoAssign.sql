/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_Deal_AutoAssign]
    @ProcessDate DATETIME = ''
AS	
/*
    Created:      20250926@Lewis
    Task:         NNCO Affiliate Monthly Migration Process – Migrate affiliates from NNCO Default Comm Group to Default Comm Group
    DB:           DBAFF12B-Affiliate_12B
    Revisions:
        - 20250926@Lewis: Init SP [RedmineID: #226884]
        - 20251016@Lewis: Extended to handle all NNCO groups using fn_GetNNCOGroupMappings() [RedmineID: #241623]

	Description:  Step 4 - Jobname: 'Affiliate_12B: Summarize Data Monthly'
	Dependencies: fn_GetNNCOGroupMappings() - Inline table-valued function for NNCO group mappings
*/
BEGIN
    SET NOCOUNT ON;

    -- Initialize variables
    DECLARE @ProcessMonth DATETIME,
            @TwoMonthsAgo DATETIME,
            @SystemUserId INT = 1000000000, -- sa
            @AssignErrCode INT = 0,
            @AssignErrMsg NVARCHAR(MAX)= '';

    -- Calculate month boundaries
    SET @ProcessMonth = DATEFROMPARTS(YEAR(@ProcessDate), MONTH(@ProcessDate), 1);
    SET @TwoMonthsAgo = DATEADD(MONTH, -2, @ProcessMonth);

    -- Step 1: Find affiliates currently in NNCO Default Comm Group (from AffInfo)
    -- who have been approved for at least 2 full months
    DECLARE @EligibleAffiliates TABLE (AffId INT, CurrentGroupId INT, TargetGroupId INT, ApprovedDate DATETIME, Id INT IDENTITY(1,1))
	INSERT INTO @EligibleAffiliates (AffId, CurrentGroupId, TargetGroupId, ApprovedDate)
    SELECT 
        ai.AffId,
        ai.GroupId,
        nm.TargetGroupId,
        ai.ApprovedDate
    FROM dbo.AffInfo ai WITH (NOLOCK)
        INNER JOIN dbo.Aff_f_GetNNCOGroupMappings() nm ON ai.GroupId = nm.SourceGroupId
    WHERE ai.Status = 'Approved' AND ai.IsRejected = 0 -- only Approved Aff
        AND ai.ApprovedDate IS NOT NULL
        AND CAST(ai.ApprovedDate AS DATE) <= @TwoMonthsAgo  -- Approved at least 2 months ago
    
    -- Step 2: Use Aff_Admin_Assign_Deal SP to properly assign affiliates to Default Comm Group
    DECLARE @Id INT = 1,
			@CurrentAffId INT,
			@CurrentTargetGroupId INT,
			@AssignmentCount INT = 0;
    
	DECLARE @MaxId INT = (SELECT COUNT(1) FROM @EligibleAffiliates)

    WHILE @Id <= @MaxId
    BEGIN
        -- Get next unprocessed affiliate with their target group
        SELECT @CurrentAffId = AffId, @CurrentTargetGroupId = TargetGroupId
        FROM @EligibleAffiliates 
        WHERE Id = @Id
        
        -- Call existing SP to assign deal (this handles all business logic)
        EXEC dbo.Aff_Admin_Assign_Deal 
            @UserId = @SystemUserId,
            @AffId = @CurrentAffId,
            @GroupId = @CurrentTargetGroupId,
            @IP = '',
            @ErrCode = @AssignErrCode OUTPUT,
            @ErrMsg = @AssignErrMsg OUTPUT;

        -- Next Id
        SET @Id += 1
    END;
END;
GO