/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Component_Sel]
    @ComponentId INT = NULL,
    @ComponentTypeId INT,
    @StatusIds VARCHAR(50) = ''
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: List of Components

    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]

    Param's Explanation:
        - @ComponentId:
            + NULL     : indicates dropdown list behavior
            + not NULL : indicates popup behavior
        - @ComponentTypeId:
            + 0       : all component types
            + >0      : specific component type
        - @StatusIds:
            + '0,1'   : all status
            + '1'     : single status (Active)
            + '0'     : single status (Inactive)
*/
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Status TABLE (StatusId TINYINT);

    IF @ComponentId IS NOT NULL
    BEGIN
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
        INSERT INTO @Status(StatusId)
        SELECT CAST(f.value AS TINYINT)
        FROM STRING_SPLIT(@StatusIds, ',') f;

        SELECT c.ComponentId
              ,c.ComponentName
              ,c.ComponentCode
              ,c.ComponentTypeId
              ,c.StatusId
              ,s.Status
        FROM dbo.LandingPage_Component c WITH (NOLOCK)
            INNER JOIN dbo.Aff_f_LandingPage_Component_Status() s 
                ON s.StatusId = c.StatusId
        WHERE EXISTS(SELECT 1 FROM @Status st WHERE st.StatusId = c.StatusId)
            AND c.ComponentTypeId = @ComponentTypeId
        ORDER BY c.ComponentId DESC;
    END
END
GO