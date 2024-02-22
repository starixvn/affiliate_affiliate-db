/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GroupProduct]
(
)
RETURNS TABLE
AS

/*
	Created: 20240222@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function get group product

	Revisions:
		- 20240222@Sally: Initialize SP [RedmineID: #199895]
*/

RETURN
	SELECT 71 AS ProductId, 71 AS GroupProductId
	UNION ALL
	SELECT 72, 71
GO
