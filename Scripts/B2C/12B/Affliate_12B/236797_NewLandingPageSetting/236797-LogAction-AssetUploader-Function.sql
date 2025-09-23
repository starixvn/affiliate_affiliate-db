/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250918@Sally	
	Task: Add log action for Asset Uploader related stored procedures
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250918@Sally: Created [RedmineID: #236797]

	Description:
		- Add log action for Asset Uploader related stored procedures
*/
USE Affiliate_12B
GO
-- Add log action for Asset Uploader related stored procedures
INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, IsInternal, Items, Description, ActionName)
SELECT ActionId, ActionTypeId, SPName, IsInternal, Items, Description, ActionName
FROM (
    -- ActionId: 104 - Insert Asset Uploader
    SELECT 
        104 AS ActionId,
        30 AS ActionTypeId,
        'Aff_LandingPage_AssetUploader_Ins' AS SPName,
        0 AS IsInternal,
        '{
          "Items": [
            {"Alias": "ai", "Item": "Asset Information"},
            {"Alias": "fn", "Item": "Form Name"},
            {"Alias": "f", "Item": "File Name"},
            {"Alias": "m", "Item": "Module"},
            {"Alias": "d", "Item": "Dimension"},
            {"Alias": "tc", "Item": "Target Country"},
            {"Alias": "l", "Item": "Language"},
            {"Alias": "st", "Item": "Active"}
          ]
        }' AS Items,
        NULL AS Description,
        'Insert Asset Uploader' AS ActionName
    
    UNION ALL
    
    -- ActionId: 105 - Update Asset Uploader
    SELECT 
        105 AS ActionId,
        30 AS ActionTypeId,
        'Aff_LandingPage_AssetUploader_Upd' AS SPName,
        0 AS IsInternal,
        '{
          "Items": [
            {"Alias": "ai", "Item": "Asset Information"},
            {"Alias": "fn", "Item": "Form Name"},
            {"Alias": "f", "Item": "File Name"},
            {"Alias": "m", "Item": "Module"},
            {"Alias": "d", "Item": "Dimension"},
            {"Alias": "tc", "Item": "Target Country"},
            {"Alias": "l", "Item": "Language"},
            {"Alias": "st", "Item": "Active"}
          ]
        }' AS Items,
        NULL AS Description,
        'Update Asset Uploader' AS ActionName
    
    UNION ALL
    
    -- ActionId: 106 - Delete Asset Uploader
    SELECT 
        106 AS ActionId,
        30 AS ActionTypeId,
        'Aff_LandingPage_AssetUploader_Del' AS SPName,
        0 AS IsInternal,
        '{
          "Items": [
            {"Alias": "ai", "Item": "Asset Information"},
            {"Alias": "fn", "Item": "Form Name"},
            {"Alias": "f", "Item": "File Name"},
            {"Alias": "m", "Item": "Module"},
            {"Alias": "d", "Item": "Dimension"},
            {"Alias": "tc", "Item": "Target Country"},
            {"Alias": "l", "Item": "Language"},
            {"Alias": "st", "Item": "Active"}
          ]
        }' AS Items,
        NULL AS Description,
        'Delete Asset Uploader' AS ActionName
    
    UNION ALL
    
    -- ActionId: 107 - Update Asset Uploader Status
    SELECT 
        107 AS ActionId,
        30 AS ActionTypeId,
        'Aff_LandingPage_AssetUploader_Status_Upd' AS SPName,
        0 AS IsInternal,
        '{
          "Items": [
            {"Alias": "ai", "Item": "Asset Information"},
            {"Alias": "fn", "Item": "Form Name"},
            {"Alias": "f", "Item": "File Name"},
            {"Alias": "st", "Item": "Active"}
          ]
        }' AS Items,
        NULL AS Description,
        'Update Asset Uploader Status' AS ActionName
) AS SourceData
WHERE NOT EXISTS (
    -- Only insert records where the ActionId doesn't already exist
    SELECT 1 
    FROM dbo.LogAction WITH(NOLOCK)
    WHERE ActionId = SourceData.ActionId
);
PRINT 'Script execution completed.';