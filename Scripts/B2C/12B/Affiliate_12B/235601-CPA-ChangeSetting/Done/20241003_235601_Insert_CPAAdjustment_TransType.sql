/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20241003@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task: Insert new transaction type 208 'CPA Adjustment' into AffTrans table
    RedmineID: #235601
    
    Purpose: Add new transaction type for CPA commission adjustments
    Business Context: Support CPA adjustment transactions in affiliate commission system
*/

USE Affiliate_12B
GO

-- Insert new transaction type 208
INSERT INTO dbo.TransType (TypeId, TypeName, TypeDesc)
VALUES (208, 'CPA Adjustment', 'CPA Adjustment'),
(209, 'CPA Tentative', 'CPA Tentative');
GO