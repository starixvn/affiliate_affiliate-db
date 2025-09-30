/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250930@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Insert LogAction data for LandingPage Component features [RedmineId : #239988]
        - Insert LogAction data for Component management stored procedures
*/

USE Affiliate_12B;
GO

-- Insert LogAction entries
INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, ActionName, IsInternal, Items)
VALUES 
-- Asset Uploader Management
(104, 30, 'Aff_LandingPage_AssetUploader_Ins', 'Insert Asset Uploader', 0,
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
}'),
(105, 30, 'Aff_LandingPage_AssetUploader_Upd', 'Update Asset Uploader', 0,
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
}'),
(106, 30, 'Aff_LandingPage_AssetUploader_Del', 'Delete Asset Uploader', 0,
'{
    "Items": [
        {"Alias": "ai", "Item": "Asset Information"},
        {"Alias": "fn", "Item": "Form Name"},
        {"Alias": "f", "Item": "File Name"},
        {"Alias": "m", "Item": "Module"},
        {"Alias": "d", "Item": "Dimension"},
        {"Alias": "tc", "Item": "Target Country"},
        {"Alias": "l", "Item": "Language"},
        {"Alias": "st", "Item": "Status"}
    ]
}'),
(107, 30, 'Aff_LandingPage_AssetUploader_Status_Upd', 'Update Asset Uploader Status', 0,
'{
    "Items": [
        {"Alias": "ai", "Item": "Asset Information"},
        {"Alias": "fn", "Item": "Form Name"},
        {"Alias": "f", "Item": "File Name"},
        {"Alias": "st", "Item": "Status"}
    ]
}'),

-- Component Management
(112, 30, 'Aff_LandingPage_Component_Ins', 'Insert Component', 0, 
'{
    "Items": [
        {"Alias": "ci", "Item": "Component Id"},
        {"Alias": "cc", "Item": "Component Code"},
        {"Alias": "cn", "Item": "Component Name"},
        {"Alias": "ct", "Item": "Component Type Id"},
        {"Alias": "st", "Item": "Status"}
    ]
}'),
(113, 30, 'Aff_LandingPage_Component_Upd', 'Update Component', 0, 
'{
    "Items": [
        {"Alias": "ci", "Item": "Component Id"},
        {"Alias": "cc", "Item": "Component Code"},
        {"Alias": "cn", "Item": "Component Name"},
        {"Alias": "ct", "Item": "Component Type Id"},
        {"Alias": "st", "Item": "Status"}
    ]
}'),
(114, 30, 'Aff_LandingPage_Deal_Upd', 'Update Deal Status', 0, 
'{
    "Items": [
        {"Alias": "di", "Item": "Deal Id"},
        {"Alias": "dn", "Item": "Deal Name"},
        {"Alias": "st", "Item": "Status"}
    ]
}');
GO