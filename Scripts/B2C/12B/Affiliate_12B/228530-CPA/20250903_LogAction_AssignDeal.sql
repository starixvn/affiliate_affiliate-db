/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250903@Lewis.Cao
    DB: DBAFF12B.Affiliate_12B
    Task: Log for assign [RedmineID: #228530]
*/
USE Affiliate_12B
GO

INSERT INTO LogAction (ActionId, ActionTypeId, SPName, ActionName, IsInternal, Items)
VALUES
(56, 29, 'Aff_Admin_Assign_Deal', 'Assign Affiliate Deal', 0, '{"Items": [
  {"Alias": "da", "Item": "Deal Assignment"},
  {"Alias": "dn", "Item": "Deal Name"},
  {"Alias": "dt", "Item": "Deal Type"},
  {"Alias": "ad", "Item": "Affected Date"}
]}')