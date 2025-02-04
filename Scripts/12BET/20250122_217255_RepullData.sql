/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250122@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Repull Data [RedmineId : #217255]
*/
USE Affiliate_12BET
GO

DECLARE @winlostdate SMALLDATETIME = '2025-01-18'

EXEC dbo.Task_Aff_ImportData_CheckData @winlostdate = @winlostdate, @isCheckOnly = 0


SELECT @winlostdate = '2025-01-17'

EXEC dbo.Task_Aff_ImportData_CheckData @winlostdate = @winlostdate, @isCheckOnly = 0

GO