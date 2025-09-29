/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Component_ManageSel]
    @ComponentTypeId INT,
    @ComponentName VARCHAR(200) = '',
    @StatusIds VARCHAR(50) = ''
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Select Landing Page Components for management grid with filtering
    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]
*/
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.ComponentId,
        c.ComponentName,
        c.ComponentTypeId,
        c.CreatedDate,
        u.UserName AS CreatedBy,
        c.Creator AS CreatorId,
        c.UpdatedDate AS LastModifiedDate,
        au.UserName AS LastModifiedBy,
        c.UpdatedBy AS LastModifiedById,
        CASE c.StatusId 
            WHEN 1 THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END AS IsActive
    FROM dbo.LandingPage_Component c WITH (NOLOCK)
    INNER JOIN dbo.Affiliate_User u WITH (NOLOCK) ON u.CustId = c.Creator
    INNER JOIN dbo.Affiliate_User au WITH (NOLOCK) ON au.CustId = c.UpdatedBy
    WHERE (c.ComponentTypeId = @ComponentTypeId)
        AND (@ComponentName = '' OR c.ComponentName LIKE '%' + @ComponentName + '%')
        AND (@StatusIds = '' OR ',' + @StatusIds + ',' LIKE '%,' + CONVERT(VARCHAR(10), c.StatusId) + ',%')
    ORDER BY c.ComponentTypeId ASC, c.ComponentName ASC;
END;