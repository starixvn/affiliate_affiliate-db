/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Component_Sel]
    @ComponentId INT = NULL,
    @ComponentTypeId INT
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: List of Components

    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]
        - 20250929@Sophia: Removed @StatusIds parameter, simplified to only show active components [RedmineID: #239988]

    Param's Explanation:
        - @ComponentId:
            + NULL     : indicates dropdown list behavior (returns only active components)
            + not NULL : indicates popup behavior (returns component regardless of status)
        - @ComponentTypeId:
            + 0       : all component types
            + >0      : specific component type
*/
BEGIN
    SET NOCOUNT ON;

    IF @ComponentId IS NOT NULL
    BEGIN
        -- Get specific component regardless of status
        SELECT c.ComponentId
              ,c.ComponentName
              ,c.ComponentCode
              ,c.ComponentTypeId
              ,c.StatusId
              ,s.Status
        FROM dbo.LandingPage_Component c WITH (NOLOCK)
            INNER JOIN dbo.Aff_f_LandingPage_Component_Status() s 
                ON s.StatusId = c.StatusId
        WHERE c.ComponentId = @ComponentId
            AND c.ComponentTypeId = @ComponentTypeId 
        ORDER BY c.ComponentId DESC;
    END
    ELSE
    BEGIN
        -- List all active components for the specified type
        SELECT c.ComponentId
              ,c.ComponentName
              ,c.ComponentCode
              ,c.ComponentTypeId
              ,c.StatusId
              ,s.Status
        FROM dbo.LandingPage_Component c WITH (NOLOCK)
            INNER JOIN dbo.Aff_f_LandingPage_Component_Status() s 
                ON s.StatusId = c.StatusId
        WHERE c.StatusId = 1 -- Only active components
            AND c.ComponentTypeId = @ComponentTypeId
        ORDER BY c.ComponentId DESC;
    END;
END;
GO