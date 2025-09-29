/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Component_Status_Sel]
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: List of Component Status
    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]
*/
BEGIN
    SET NOCOUNT ON;

    SELECT StatusId, Status
    FROM dbo.Aff_f_LandingPage_Component_Status()
    ORDER BY StatusId ASC;
END
GO