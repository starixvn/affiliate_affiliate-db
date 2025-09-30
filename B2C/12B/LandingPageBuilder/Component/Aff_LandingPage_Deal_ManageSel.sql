/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Deal_ManageSel]
    @DealName   NVARCHAR(100) = '',
    @StatusIDs  VARCHAR(50) = '1' -- Default to active status
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Select Landing Page Deals for Management

    Revisions:  
        - 20250929@Sophia: Initialize SP [RedmineID: #239988]

    Param's Explanation:
        - @DealName: Filter deals by name (partial match)
        - @StatusIDs: Comma-separated list of status IDs
            + 1: Active
            + 2: Inactive
*/
BEGIN
    SET NOCOUNT ON;
    
    -- Clean input
    SELECT @DealName = NULLIF(LTRIM(RTRIM(@DealName)), '');
    
    -- Create table variable for StatusIDs
    DECLARE @StatusIDTable TABLE (StatusId INT);
    
    -- Split and insert status IDs
    INSERT INTO @StatusIDTable (StatusId)
    SELECT CAST(value AS INT)
    FROM STRING_SPLIT(@StatusIDs, ',');

    -- Get list of deals with additional management information
    SELECT 
        ld.DealId,
        cg.GroupName AS DealName,
        ld.StatusId,
        s.Status AS Status,
        ld.Creator AS CreatorId,
        ISNULL(u.UserName, '') AS CreatedBy,
        ld.CreatedDate,
        ISNULL(ld.UpdatedBy, 0) AS UpdatedById,
        ISNULL(au.UserName, '') AS UpdatedBy,
        ISNULL(ld.UpdatedDate, '') AS UpdatedDate
    FROM dbo.LandingPage_Deal ld WITH (NOLOCK)
    INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ld.DealId = cg.GroupId
    INNER JOIN dbo.Aff_f_LandingPage_Component_Status() s ON s.StatusId = ld.StatusId
    LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON u.CustId = ld.Creator
    LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON au.CustId = ld.UpdatedBy
    WHERE ld.StatusId IN (SELECT StatusId FROM @StatusIDTable)
        AND (@DealName = ''
            OR cg.GroupName LIKE '%' + @DealName + '%')
    ORDER BY ld.DealId DESC;
END;