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
        c.ComponentCode,
        c.ComponentName,
        c.ComponentTypeId,
        c.CreatedDate,
        ISNULL(u.UserName, '') AS CreatedBy,
        c.Creator AS CreatorId,
        ISNULL(c.UpdatedDate, '') AS LastModifiedDate,
        ISNULL(au.UserName, '') AS LastModifiedBy,
        ISNULL(c.UpdatedBy, 0) AS LastModifiedById,
        c.StatusId,
        s.Status
    FROM dbo.LandingPage_Component c WITH (NOLOCK)
    LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON u.CustId = c.Creator
    LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON au.CustId = c.UpdatedBy
    LEFT JOIN dbo.Aff_f_LandingPage_Component_Status() s ON s.StatusId = c.StatusId
    WHERE (c.ComponentTypeId = @ComponentTypeId)
        AND (@ComponentName = '' 
            OR c.ComponentName LIKE '%' + @ComponentName + '%'
            OR c.ComponentCode LIKE '%' + @ComponentName + '%')
        AND (@StatusIds = '' OR ',' + @StatusIds + ',' LIKE '%,' + CONVERT(VARCHAR(10), c.StatusId) + ',%')
    ORDER BY c.ComponentId DESC;
END;