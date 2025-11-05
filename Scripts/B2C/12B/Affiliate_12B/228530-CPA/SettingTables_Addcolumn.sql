/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250623@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task:	Schedule           [RedmineID: #228530]
			DealBillingSchedule
			CommGroup
			CPAGroupSetting
			LogAction
*/
USE Affiliate_12B


-- Update ActionId 53 (Add new Deal)
UPDATE LogAction WITH (UPDLOCK, ROWLOCK)
SET Items = '{"Items": [
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
  {"Alias": "rr", "Item": "Redeposit Rate"},
  {"Alias": "rd", "Item": "Redeposit Days"},
  {"Alias": "pf", "Item": "Payment Frequency"},
  {"Alias": "sd", "Item": "Start Date"},
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
]}'
WHERE ActionId = 53
  AND ActionTypeId = 29;
GO
-- Update ActionId 54 (Update Deal)
UPDATE LogAction WITH (UPDLOCK, ROWLOCK)
SET Items = '{"Items": [
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
  {"Alias": "rr", "Item": "Redeposit Rate"},
  {"Alias": "rd", "Item": "Redeposit Days"},
  {"Alias": "pf", "Item": "Payment Frequency"},
  {"Alias": "sd", "Item": "Start Date"},
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
]}'
WHERE ActionId = 54
  AND ActionTypeId = 29;
GO
-- Update ActionId 55 (Delete Deal)
UPDATE LogAction WITH (UPDLOCK, ROWLOCK)
SET Items = '{"Items": [
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
  {"Alias": "rr", "Item": "Redeposit Rate"},
  {"Alias": "rd", "Item": "Redeposit Days"},
  {"Alias": "pf", "Item": "Payment Frequency"},
  {"Alias": "sd", "Item": "Start Date"},
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
]}'
WHERE ActionId = 55
  AND ActionTypeId = 29;
GO
 CREATE TABLE DealBillingSchedule (
        GroupId int NOT NULL,
        ScheduleId tinyint NOT NULL,
        NextBillingDate date NULL,
        CONSTRAINT PK_DealBillingSchedule PRIMARY KEY (GroupId, ScheduleId)
    ) ON [SettingData];
GO
CREATE TABLE Schedule (
        ScheduleID tinyint NOT NULL,
        ScheduleName varchar(200) NOT NULL,
        IntervalType varchar(20) NOT NULL,
        IntervalValue smallint NOT NULL,
        CONSTRAINT PK_Schedule_ScheduleID PRIMARY KEY CLUSTERED (ScheduleID)
    ) ON [SettingData];
GO

INSERT INTO Schedule (ScheduleID, ScheduleName, IntervalValue, IntervalType)
VALUES (1, 'Daily', 1, 'Day'),
       (2, 'Every 7 days', 7, 'Day'),
       (3, 'Every 10 days', 10, 'Day'),
       (4, 'Every 15 days', 15, 'Day'),
       (5, 'Monthly', 1, 'Month');
GO

ALTER TABLE CPAGroupSetting 
ADD 
        RedepositRate decimal(9,8) NULL,
        RedepositDays smallint NULL,
        StartDate date NULL,
        ScheduleId smallint NULL;
GO

ALTER TABLE CommGroup 
ADD 
        RedepositRate decimal(9,8) NULL,
        RedepositDays smallint NULL,
        StartDate date NULL,
        ScheduleId smallint NULL;
GO