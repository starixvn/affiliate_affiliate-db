/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_GetMoveBetsDay]
(
)
RETURNS SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core function - Get MoveBetsDay

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

BEGIN
	DECLARE @MoveBetsDay SMALLDATETIME
	
	SELECT  @MoveBetsDay = eventdate
	FROM OPENQUERY(DBEXT, 'SELECT MAX(eventdate) AS eventdate FROM bodb02.dbo.match14 WITH (NOLOCK)')

	RETURN  @MoveBetsDay
END
GO