/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_CheckData_Job]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Import data of IBC's Products from bettrans (MoveBetsDays)

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @winlostdate SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
		
	SELECT @MoveBetsDay = MAX(eventdate)
	FROM bodb02.dbo.match14 WITH(NOLOCK)
		
	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE matchid = 0 AND bettype = 20000
		
	SELECT @winlostdate = @BalanceUpDay
		
	WHILE(@winlostdate <= @MoveBetsDay)
	BEGIN
		EXEC dbo.Task_Aff_ImportData_CheckData @winlostdate = @winlostdate, @isCheckOnly = 0
			
		SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
	END
END
GO