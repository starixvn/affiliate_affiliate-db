/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250919@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Insert LogAction data for LandingPage Builder features [RedmineId : #236797]
        - Insert LogType data for LandingPage module
        - Insert LogAction data for all Landing Page Builder stored procedures
*/

USE Affiliate_12B;
GO

-- 1. Insert LogType data
DELETE FROM dbo.LogType WHERE TypeId = 30;
INSERT INTO dbo.LogType (TypeId, TypeName, Description)
VALUES (30, 'LandingPage', 'Landing Page Builder Management');

-- 2. Insert LogAction data
-- First, clean up existing entries if any
DELETE FROM dbo.LogAction WHERE ActionTypeId = 30;

-- Insert new LogAction entries
INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, ActionName, IsInternal, Items)
VALUES 
-- API
(101, 30, 'API_SignUp', 'API Sign in', 0, 
'{
    "Items": [
        {"Alias": "u", "Item": "User name"},
        {"Alias": "e", "Item": "Email"},
        {"Alias": "ph", "Item": "Phone Number"},
        {"Alias": "cu", "Item": "Currency"},
        {"Alias": "ac", "Item": "Area Code"},
        {"Alias": "ct", "Item": "Captcha Type"},
        {"Alias": "rct", "Item": "ReCaptchaToken"},
        {"Alias": "ru", "Item": "Referral Url"},
        {"Alias": "l", "Item": "User Lang"},
        {"Alias": "st", "Item": "Status"},
        {"Alias": "dur", "Item": "Duration"}
    ]
}'),

-- Campaign Management
(102, 30, 'Aff_LandingPage_Campaign_Ins', 'Insert Campaign', 0, 
'{
    "Items": [
        {"Alias": "ci", "Item": "Campaign Id"},
        {"Alias": "cc", "Item": "Campaign Code"},
        {"Alias": "cn", "Item": "Campaign Name"},
        {"Alias": "d", "Item": "Description"},
        {"Alias": "st", "Item": "Status"}
    ]
}'),
(103, 30, 'Aff_LandingPage_Campaign_Upd', 'Update Campaign', 0, 
'{    "Items": [
        {"Alias": "ci", "Item": "Campaign Id"},
        {"Alias": "cc", "Item": "Campaign Code"},
        {"Alias": "cn", "Item": "Campaign Name"},
        {"Alias": "d", "Item": "Description"},
        {"Alias": "st", "Item": "Status"}
    ]
}'),
 
-- Deal Management
(108, 30, 'Aff_LandingPage_Deal_Ins', 'Insert New Deal for Landing Page', 0,
'{
    "Items": [
        {"Alias": "d", "Item": "DealId"},
        {"Alias": "dn", "Item": "Deal Name"}
    ]
}'),

-- Page Builder Management
(109, 30, 'Aff_LandingPage_Builder_Ins', 'Insert Page Builder', 0,
'{
    "Items": [
        {"Alias": "lp", "Item": "Landing Page"},
        {"Alias": "pid", "Item": "PageId"},
        {"Alias": "pn", "Item": "Page Name"},
        {"Alias": "pc", "Item": "Page Code"},
        {"Alias": "tc", "Item": "Target Country"},
        {"Alias": "l", "Item": "Language"},
        {"Alias": "st", "Item": "Status"},
        {"Alias": "cc", "Item": "Campaign Code"},
        {"Alias": "dn", "Item": "Deal Names"},
        {"Alias": "prv", "Item": "IsPreview"},
        {"Alias": "cs", "Item": "ComponentStructure"}
    ]
}'),
(110, 30, 'Aff_LandingPage_Builder_Upd', 'Update Page Builder', 0, 
'{
    "Items": [
        {"Alias": "lp", "Item": "Landing Page"},
        {"Alias": "pid", "Item": "PageId"},
        {"Alias": "pn", "Item": "Page Name"},
        {"Alias": "pc", "Item": "Page Code"},
        {"Alias": "tc", "Item": "Target Country"},
        {"Alias": "l", "Item": "Language"},
        {"Alias": "st", "Item": "Status"},
        {"Alias": "cc", "Item": "Campaign Code"},
        {"Alias": "dn", "Item": "Deal Names"},
        {"Alias": "prv", "Item": "IsPreview"},
        {"Alias": "cs", "Item": "ComponentStructure"}
    ]
}'),
(111, 30, 'Aff_LandingPage_Builder_RowVersion_Upd', 'Update Page Builder Row Version', 0, 
'{
    "Items": [
        {"Alias": "lp", "Item": "Landing Page"},
        {"Alias": "pid", "Item": "PageId"},
        {"Alias": "pn", "Item": "Page Name"},
        {"Alias": "pc", "Item": "Page Code"},
        {"Alias": "tc", "Item": "Target Country"},
        {"Alias": "l", "Item": "Language"},
        {"Alias": "st", "Item": "Status"},
        {"Alias": "cc", "Item": "Campaign Code"},
        {"Alias": "dn", "Item": "Deal Names"},
        {"Alias": "prv", "Item": "IsPreview"},
        {"Alias": "cs", "Item": "ComponentStructure"}
    ]
}');
 