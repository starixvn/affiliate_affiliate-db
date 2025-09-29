/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[Aff_f_LandingPage_Component_Status]()
RETURNS TABLE
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Table-valued function for Component Status
    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]
*/
AS
RETURN
(
    SELECT StatusId, Status
    FROM (
        VALUES (0, 'Inactive')
              ,(1, 'Active')
    ) AS StatusTable(StatusId, Status)
)
GO