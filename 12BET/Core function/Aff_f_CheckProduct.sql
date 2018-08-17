/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_CheckProduct]
(
	@ProductId		INT,
	@IsBettrans		BIT,
	@WinlostDate	SMALLDATETIME,
	@MoveBetsDay	SMALLDATETIME
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core function - Check Product enable/disable

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

RETURN
	SELECT ProductId, ProductName, ProductPrefix
	FROM dbo.Products WITH (NOLOCK)
	WHERE ProductId = @ProductId
		AND (EndOfSupportDate IS NULL OR DATEDIFF(MONTH, EndOfSupportDate, @WinlostDate) < 0)
		AND (
			@IsBettrans = 1
			OR (IsIBC = 0 OR @WinlostDate <= @MoveBetsDay)
		)
GO