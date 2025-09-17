/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250623@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task: Step3 LoggingTables DDL and initial data for LogAction, UserLog_RunSP_Detail, LogType
*/

-- LogAction table
ALTER TABLE LogAction
    ADD IsInternal bit NULL,
        Items varchar(max) NULL,
        ActionName varchar(256) NULL;
GO

-- UserLog_RunSP_Detail: add Duration
ALTER TABLE UserLog_RunSP_Detail
    ADD Duration smallint NULL;
GO

-- LogType: Insert new type for Deals
INSERT INTO LogType (TypeId, TypeName, Description)
VALUES (29, 'Deal', 'Deal');
GO

-- Initial data for LogAction (Deal actions)
INSERT INTO LogAction (ActionId, ActionTypeId, SPName, ActionName, IsInternal, Items)
VALUES
(53, 29, 'Aff_Admin_Deal_Ins', 'Add new Deal', 0, '{"Items": [
  {"Alias": "di", "Item": "Deal Information"},
  {"Alias": "dn", "Item": "Deal Name"},
  {"Alias": "dt", "Item": "Deal Type"},
  {"Alias": "d", "Item": "Description"},
  {"Alias": "sr", "Item": "Sub Rate"},
  {"Alias": "ci", "Item": "CPA Information"},
  {"Alias": "tc", "Item": "Target Country"},
  {"Alias": "ap", "Item": "Active Period"},
  {"Alias": "hd", "Item": "Holding Days"},
  {"Alias": "ht", "Item": "Holding Tickets"},
  {"Alias": "q", "Item": "Quota"},
  {"Alias": "ip", "Item": "Instant Payment"},
  {"Alias": "ct", "Item": "CPA Tier"},
  {"Alias": "cpg", "Item": "CPA Product Group"},
  {"Alias": "cti", "Item": "Tier"},
  {"Alias": "fdm", "Item": "Min FDM"},
  {"Alias": "tdm", "Item": "Min Total Deposit"},
  {"Alias": "w", "Item": "Min Wagering"},
  {"Alias": "cpa", "Item": "CPA Amount"},
  {"Alias": "ri", "Item": "Revenue Share Information"},
  {"Alias": "qpt", "Item": "QP Turnover"},
  {"Alias": "cqp", "Item": "Count QP"},
  {"Alias": "rt", "Item": "Revenue Share Tier"},
  {"Alias": "rpg", "Item": "Rev Share Product Group"},
  {"Alias": "rti", "Item": "Rev Share Tier"},
  {"Alias": "rf", "Item": "Royalty Fee"},
  {"Alias": "nw", "Item": "Min Net Win"},
  {"Alias": "qp", "Item": "Min Qualified Member"},
  {"Alias": "rs", "Item": "Rev Share %"},
  {"Alias": "df", "Item": "Deposit Fee"},
  {"Alias": "dfx", "Item": "Deposit Fee Fix Amount"},
  {"Alias": "wf", "Item": "Withdrawal Fee"},
  {"Alias": "wfx", "Item": "Withdrawal Fee Fix Amount"},
  {"Alias": "fd", "Item": "From Date"},
  {"Alias": "td", "Item": "To Date"}
]}'),
(54, 29, 'Aff_Admin_Deal_Upd', 'Update Deal', 0, '{"Items": [
  {"Alias": "di", "Item": "Deal Information"},
  {"Alias": "dn", "Item": "Deal Name"},
  {"Alias": "dt", "Item": "Deal Type"},
  {"Alias": "d", "Item": "Description"},
  {"Alias": "sr", "Item": "Sub Rate"},
  {"Alias": "ci", "Item": "CPA Information"},
  {"Alias": "tc", "Item": "Target Country"},
  {"Alias": "ap", "Item": "Active Period"},
  {"Alias": "hd", "Item": "Holding Days"},
  {"Alias": "ht", "Item": "Holding Tickets"},
  {"Alias": "q", "Item": "Quota"},
  {"Alias": "ip", "Item": "Instant Payment"},
  {"Alias": "ct", "Item": "CPA Tier"},
  {"Alias": "cpg", "Item": "CPA Product Group"},
  {"Alias": "cti", "Item": "Tier"},
  {"Alias": "fdm", "Item": "Min FDM"},
  {"Alias": "tdm", "Item": "Min Total Deposit"},
  {"Alias": "w", "Item": "Min Wagering"},
  {"Alias": "cpa", "Item": "CPA Amount"},
  {"Alias": "ri", "Item": "Revenue Share Information"},
  {"Alias": "qpt", "Item": "QP Turnover"},
  {"Alias": "cqp", "Item": "Count QP"},
  {"Alias": "rt", "Item": "Revenue Share Tier"},
  {"Alias": "rpg", "Item": "Rev Share Product Group"},
  {"Alias": "rti", "Item": "Rev Share Tier"},
  {"Alias": "rf", "Item": "Royalty Fee"},
  {"Alias": "nw", "Item": "Min Net Win"},
  {"Alias": "qp", "Item": "Min Qualified Member"},
  {"Alias": "rs", "Item": "Rev Share %"},
  {"Alias": "df", "Item": "Deposit Fee"},
  {"Alias": "dfx", "Item": "Deposit Fee Fix Amount"},
  {"Alias": "wf", "Item": "Withdrawal Fee"},
  {"Alias": "wfx", "Item": "Withdrawal Fee Fix Amount"},
  {"Alias": "fd", "Item": "From Date"},
  {"Alias": "td", "Item": "To Date"}
]}'),
(55, 29, 'Aff_Admin_Deal_Del', 'Delete Deal', 0, '{"Items": [
  {"Alias": "di", "Item": "Deal Information"},
  {"Alias": "dn", "Item": "Deal Name"},
  {"Alias": "dt", "Item": "Deal Type"},
  {"Alias": "d", "Item": "Description"},
  {"Alias": "sr", "Item": "Sub Rate"},
  {"Alias": "ci", "Item": "CPA Information"},
  {"Alias": "tc", "Item": "Target Country"},
  {"Alias": "ap", "Item": "Active Period"},
  {"Alias": "hd", "Item": "Holding Days"},
  {"Alias": "ht", "Item": "Holding Tickets"},
  {"Alias": "q", "Item": "Quota"},
  {"Alias": "ip", "Item": "Instant Payment"},
  {"Alias": "ct", "Item": "CPA Tier"},
  {"Alias": "cpg", "Item": "CPA Product Group"},
  {"Alias": "cti", "Item": "Tier"},
  {"Alias": "fdm", "Item": "Min FDM"},
  {"Alias": "tdm", "Item": "Min Total Deposit"},
  {"Alias": "w", "Item": "Min Wagering"},
  {"Alias": "cpa", "Item": "CPA Amount"},
  {"Alias": "ri", "Item": "Revenue Share Information"},
  {"Alias": "qpt", "Item": "QP Turnover"},
  {"Alias": "cqp", "Item": "Count QP"},
  {"Alias": "rt", "Item": "Revenue Share Tier"},
  {"Alias": "rpg", "Item": "Rev Share Product Group"},
  {"Alias": "rti", "Item": "Rev Share Tier"},
  {"Alias": "rf", "Item": "Royalty Fee"},
  {"Alias": "nw", "Item": "Min Net Win"},
  {"Alias": "qp", "Item": "Min Qualified Member"},
  {"Alias": "rs", "Item": "Rev Share %"},
  {"Alias": "df", "Item": "Deposit Fee"},
  {"Alias": "dfx", "Item": "Deposit Fee Fix Amount"},
  {"Alias": "wf", "Item": "Withdrawal Fee"},
  {"Alias": "wfx", "Item": "Withdrawal Fee Fix Amount"},
  {"Alias": "fd", "Item": "From Date"},
  {"Alias": "td", "Item": "To Date"}
]}');
-- End LogAction rows insert

-- End of Step3_LoggingTables.sql
