/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_ExchangeRateById_Sel]
(
	@ExchangeId		INT,
	@WinlostDate	SMALLDATETIME
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core function - Get Exchange Rate by Currency

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

RETURN
	WITH CTE_Exchange AS
	(
		SELECT ExchangeId, MAX(UpdatedTime) AS UpdateTime
		FROM dbo.Exchange WITH (NOLOCK)
		WHERE UpdatedTime <= @WinlostDate AND ExchangeId = @ExchangeId
		GROUP BY ExchangeID
	)
	SELECT
		e.ExchangeId, e.ActualRate, e.ActualRate2
	FROM CTE_Exchange c
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON c.UpdateTime = e.UpdatedTime AND c.ExchangeId = e.ExchangeId
GO