/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[Aff_f_GetNNCOGroupMappings]()
RETURNS TABLE
AS
/*
    Created:      20251016@Lewis
    Task:         NNCO Group Mapping Function - Returns hardcoded mappings for NNCO groups to target groups [RedmineID: #241623]
    DB:           DBAFF12B-Affiliate_12B
    
	Revisions:
		- 20251016@Lewis: Initialize Function [RedmineID: #241623]

    Description:  Inline table-valued function that returns the mapping between NNCO groups and their target groups
                  Used by Task_Aff_Deal_AutoAssign and other processes that need NNCO group migration rules
    
    Returns:      SourceGroupId, TargetGroupId
*/	
RETURN
(
    SELECT SourceGroupId, TargetGroupId
    FROM (VALUES 
        (47, 1)  -- NNCO - Default Comm Group → Default commgroup
        ,(61, 21) -- 50% Fix Commission - NNCO → 50% Fix Commission
        --,(60, 8026)  -- 45% Fix Commission - NNCO → 45% Fix Commission
    ) AS Mappings(SourceGroupId, TargetGroupId)
);
GO