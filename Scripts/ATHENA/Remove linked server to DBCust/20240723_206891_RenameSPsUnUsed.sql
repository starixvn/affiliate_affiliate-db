/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Created: 20241023@Sally
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet
	Task: Remove linked server to DBCust [RedmineID: #206891]
		- Step Rename SPs no longer using
*/
USE Affiliate_Athena000
GO

DECLARE @command VARCHAR(MAX)
DECLARE @tmpRenameObjectsName TABLE ( command VARCHAR(MAX), IsRename BIT)
DECLARE @tmpObjectsName TABLE ( command VARCHAR(MAX), IsRename BIT)

INSERT INTO @tmpRenameObjectsName (command)
SELECT 'sp_rename ' + name + ', DEL_' + name
 FROM dbo.sysobjects
 WHERE (type = 'P')
 AND (
	name LIKE 'AffAdmin_AccountUpdPwd%'
	OR name LIKE 'AffAdmin_AdminUpdPwd%'
	OR name LIKE 'AffAdmin_Con_AccountIns%'
	OR name LIKE 'AffAdmin_Con_AccountUpd%'
	OR name LIKE 'AffAdmin_Con_CheckPermission%'
	OR name LIKE 'AffAdmin_Con_GroupInfoDel%'
	OR name LIKE 'AffAdmin_Con_GroupInfoIns%'
	OR name LIKE 'AffAdmin_Con_GroupInfoUpd%'
	OR name LIKE 'AffAdmin_Con_GroupPolicySel%'
	OR name LIKE 'AffAdmin_UserCurrencyIns%'
)

WHILE (1=1)
BEGIN
	UPDATE TOP (1) @tmpRenameObjectsName
	SET @command = command, IsRename = 1
	WHERE IsRename IS NULL

	IF @@ROWCOUNT = 0 BREAK;
	
	EXEC (@command)

END
SELECT * FROM @tmpRenameObjectsName




