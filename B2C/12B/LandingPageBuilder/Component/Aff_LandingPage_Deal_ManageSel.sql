/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Deal_ManageSel]
    @DealName   VARCHAR(100) = '',
    @StatusIDs  VARCHAR(50) = '', -- Default to active status
    @DealTypes  VARCHAR(50) = ''   -- Comma-separated list of GroupTypeId from CommGroup
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Select Landing Page Deals for Management

    Revisions:  
        - 20250929@Sophia: Initialize SP [RedmineID: #239988]
        - 20251001@Sophia: Add @DealTypes parameter to filter by GroupTypeId [RedmineID: #239988]

    Param's Explanation:
        - @DealName: Filter deals by name (partial match)
        - @StatusIDs: Comma-separated list of status IDs
            + 1: Active
            + 2: Inactive
        - @DealTypes: Comma-separated list of GroupTypeId to filter deals by type
*/
BEGIN
    SET NOCOUNT ON;
    
    -- Clean input
    SELECT @DealName = NULLIF(LTRIM(RTRIM(@DealName)), '');
    
    -- Clean input
    SELECT @DealTypes = NULLIF(LTRIM(RTRIM(@DealTypes)), '');

    -- Create table variables for StatusIDs and DealTypes
    DECLARE @StatusIDTable TABLE (StatusId INT);
    DECLARE @DealTypeTable TABLE (GroupTypeId INT);
    
    -- Split and insert status IDs
    INSERT INTO @StatusIDTable (StatusId)
    SELECT CAST(value AS INT)
    FROM STRING_SPLIT(@StatusIDs, ',')
    WHERE value <> '';

    -- Split and insert deal types
    INSERT INTO @DealTypeTable (GroupTypeId)
    SELECT CAST(value AS INT)
    FROM STRING_SPLIT(@DealTypes, ',')
    WHERE value <> '';

    -- Get list of deals with additional management information
    SELECT 
        ld.DealId,
        cg.GroupName AS DealName,
        cg.GroupTypeId,
        gt.GroupTypeName,
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
    INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON cg.GroupTypeId = gt.GroupTypeId 
    INNER JOIN dbo.Aff_f_LandingPage_Component_Status() s ON s.StatusId = ld.StatusId
    LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON u.CustId = ld.Creator
    LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON au.CustId = ld.UpdatedBy
    WHERE  ( @StatusIds = '' 
            OR EXISTS (SELECT 1 FROM @StatusIDTable st WHERE st.StatusId = ld.StatusId))
        AND (@DealName = ''
            OR cg.GroupName LIKE '%' + @DealName + '%')
        AND (@DealTypes = ''
            OR EXISTS (SELECT 1 FROM @DealTypeTable dt WHERE dt.GroupTypeId = cg.GroupTypeId))
    ORDER BY ld.DealId DESC;
END;