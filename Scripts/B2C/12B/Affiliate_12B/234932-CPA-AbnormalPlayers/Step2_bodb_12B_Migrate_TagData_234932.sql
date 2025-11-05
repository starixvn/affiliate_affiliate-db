/*<info serverAlias="DB12B-bodb_12B" ></info>*/
/*  
	Created: 20250804@Sally
	DB: DB12B-bodb_12B
	Task: Cover Abnormal players
        - Migrate Tag data from MySQL Siebog.Tag to SQL Server Tag table
*/
USE bodb_12B
GO

-- Create temporary table to store MySQL data
IF OBJECT_ID('tempdb..#TempTag') IS NOT NULL
    DROP TABLE #TempTag

CREATE TABLE #TempTag (
    Id int,
    TagName varchar(45),
    Description varchar(80),
    Status int,
    UpdateTime datetime,
    IsAbnormal tinyint
)

-- Insert data from MySQL Siebog.Tag into temp table
INSERT INTO #TempTag (Id, TagName, Description, Status, UpdateTime, IsAbnormal) VALUES
(-1, 'Robot', 'Malicious bot.', 1, '2025-05-22 10:05:46', 1),
(6, 'Duplicate', 'Member Duplicate Account', 1, '2025-06-11 04:36:43', 0),
(35, 'SelfExclusion', 'player request to freeze their account', 1, '2025-04-21 03:04:00', 0),
(42, 'Bonus Seeker', 'Bonus Seeker - Not Allowed to Claim Bonus', 1, '2025-02-12 07:47:52', 1),
(43, 'SBF', 'Suspicious Betting Fraud', 1, '2025-02-12 07:47:54', 1),
(44, 'Special Account - Do not lock', 'Special Account - Do not lock', 1, '2025-02-13 10:22:38', 0),
(45, 'Big Winner', 'Big winner checking', 1, '2025-02-18 07:10:04', 0),
(46, 'Under Monitoring', 'Controlled member for monitoring', 1, '2025-02-19 07:24:51', 0),
(47, 'Test Account', 'Internal Test Account - NOT ALLOW REAL MONEY PAYOUT', 1, '2025-06-10 07:12:09', 0),
(48, 'Deposit into Issue Bank Account', 'Advance credit deposit amount into Frozen /Inactive/Stop account', 1, '2025-03-12 09:12:40', 0),
(49, 'Affiliate Withdrawal Account', 'Affiliate Withdrawal Account', 1, '2025-03-11 05:30:31', 0),
(50, 'Depositor Bank Details Mismatch', 'Player bank account holder''s name minor difference', 1, '2025-03-12 09:17:44', 0),
(51, 'Deposit below minimum', 'Member deposit below minimum Amount', 1, '2025-03-17 08:30:49', 0),
(52, 'Akira Member - Do not suspend', 'GPI Akira Marketing - no suspend or reject withdrawal', 1, '2025-03-18 01:39:21', 0),
(53, 'Advance Credit to Missing Withdrawal ', 'Payout funds not receive', 1, '2025-03-18 10:20:37', 0),
(54, 'Red Alert', 'Tag for players RM decided to suspend, but did not suspend ', 1, '2025-03-20 01:49:11', 1),
(55, 'Claimed Lien Amount', 'Player claimed lien amount', 1, '2025-03-20 02:27:29', 0),
(56, 'NOT ALLOW TO WITHDRAW', 'TEST ACCOUNT, NOT ALLOW TO WITHDRAW', 1, '2025-03-20 08:22:11', 0),
(57, 'Advance Credit to Missing Deposit', 'Deposit Funds not yet receive', 1, '2025-03-21 13:19:18', 0),
(58, 'Deposit Lien Issue', 'Member report agent account', 0, '2025-03-21 11:16:13', 0),
(59, 'Withdrawal  Lien Issue', 'Member inform amount WD from us was hold/freeze ', 0, '2025-03-21 11:17:11', 0),
(60, 'No wcbipl25', 'Not allowed to claim wcbipl25, to close this tag on 25th May 2025', 1, '2025-04-04 08:11:09', 0),
(61, 'Player Account Dispute Issue', 'Player Account Dispute Issue', 1, '2025-04-06 01:42:12', 0),
(62, 'Disable Alipay deposit', 'Disable Alipay deposit for member', 1, '2025-04-15 14:43:14', 0),
(63, 'Disable ECNY deposit', 'Disable ECNY deposit for member', 1, '2025-04-15 14:43:47', 0),
(64, 'Disable Online Banking deposit', 'Disable Online Banking deposit for member', 1, '2025-04-15 14:44:19', 0),
(65, 'Disable EBPay deposit', 'Disable EBPay deposit for member', 1, '2025-04-15 14:54:44', 0),
(66, 'SUSPENDED Account', 'Suspended Account , not allowed to Deposit', 0, '2025-04-16 02:59:11', 0),
(67, 'manual calculate (deposit+Bonus) x18', 'manual calculate (deposit+Bonus) x18', 1, '2025-04-24 04:16:30', 0),
(68, 'Invalid Phone Number_CRM', 'Member Phone Number Invalid', 1, '2025-07-29 07:23:12', 0),
(69, 'Do Not send SMS/Call/Email_CRM', 'Member request Do Not send SMS/Call/Email', 1, '2025-07-29 07:23:09', 0),
(70, 'Disable 988 deposit', 'Disable 988 deposit for member ', 1, '2025-05-15 12:05:07', 0),
(71, 'Disable 808 deposit', 'Disable 808 deposit for member ', 1, '2025-05-15 12:07:04', 0),
(72, '1st Overpaid', '1st overpaid - member refused to return the fund', 1, '2025-05-27 11:25:39', 0),
(73, '2nd Overpaid', '2nd overpaid - member refused to return the fund', 1, '2025-05-27 11:26:14', 0),
(74, '3rd Overpaid', '3rd Overpaid -  Member refused to return the fund', 1, '2025-05-27 11:22:01', 0),
(75, 'Deposit Dispute Wrongly Claimed', 'Member Acknowledge deposit wrongly claimed', 1, '2025-05-28 12:11:39', 0),
(76, 'Deposit Dispute Adjusted to Member', 'Deposit adjusted to member(claimed by other user)', 1, '2025-05-28 12:11:56', 0),
(77, 'Hold WD', 'Withdrawal to hold for further checking', 1, '2025-06-05 14:05:23', 0),
(78, 'WD send to Doudoupay  only', 'member WD send to Doudoupay  only', 1, '2025-06-14 07:07:12', 0),
(79, 'Withdrawal do not send to Rollinsion.', 'Do not send withdrawal to Micky-Rollinsion. Try to send to Copay or Albert', 1, '2025-06-19 03:47:24', 0),
(80, 'Claimed 1 time Deposit below minimum in PG', 'Entitled to claim 1 time Deposit below min in PG', 1, '2025-07-12 08:24:43', 0),
(81, 'WD don''t process Newxy USDT', 'Have history account temporary frozen after wd receive from Newxypay USDT', 1, '2025-07-14 05:18:49', 0),
(82, 'CSD register on behalf', 'Account was registered by CS team from internal BO as requested by player.', 1, '2025-07-14 06:03:56', 0),
(83, 'Wrong Person_CRM', 'CRM called to member but wrong person', 1, '2025-07-29 07:22:43', 0),
(84, 'Not Allowed to Process DP and WD to Masalapay', 'We will continue keep this player and deposit into others PG brand mode', 1, '2025-07-20 00:45:58', 0),
(85, 'Possible Overpay', 'Due to Accidentally Rejected', 1, '2025-07-20 12:14:37', 0),
(86, 'Not allowed to Process DP and WD to WorldPay', 'We will continue to keep this player and deposit into others PG brand mode', 1, '2025-07-21 22:57:56', 0),
(87, 'Claimed 1 time Deposit below minimum in PG', 'Member deposit lower minimum in Online Payment Gateway', 1, '2025-07-22 22:10:58', 0),
(88, N'Payment Remarks: Guitar payment.', 'Remark in RMB local bank for this member''s WD temporary only', 1, '2025-07-28 07:09:53', 0),
(89, '3rd Party Test Account', '3rd Party Test Account', 1, '2025-07-29 07:22:32', 0);

-- Show data in temp table for verification
SELECT 'Records in temp table:' as Info, COUNT(1) as Count FROM #TempTag
SELECT * FROM #TempTag ORDER BY Id

-- Insert only records that don't exist in the target table
-- Note: Since SQL Server Tag table only has certain columns, we'll map accordingly

INSERT INTO [dbo].[Tag] ([Id], [TagName], [Description], [Status], [UpdateTime], [IsAbnormal])
SELECT 
    t.Id,
    t.TagName,
    t.Description,
    t.Status,
    t.UpdateTime,
    t.IsAbnormal
FROM #TempTag t
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[Tag] [target] 
    WHERE [target].Id = t.Id
)



-- Show results
SELECT 'Records inserted:' as Info, @@ROWCOUNT as Count
SELECT 'Total records in Tag table:' as Info, COUNT(1) as Count FROM [dbo].[Tag]
SELECT * FROM [dbo].[Tag] ORDER BY Id

-- Clean up temp table
DROP TABLE #TempTag

PRINT 'Migration completed successfully!'
