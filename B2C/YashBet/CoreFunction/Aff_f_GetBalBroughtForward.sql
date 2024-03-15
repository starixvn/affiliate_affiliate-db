/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" selecters="wsv_nap" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetBalBroughtForward]
(
	@AffID INT
)
RETURNS TABLE
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Get Balance Brought Forward for Affiliate by ID
	
	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

RETURN
	SELECT SUM(Amount) AS BalBroughtForward
	FROM dbo.AffTrans WITH (NOLOCK)
	WHERE AffID = @AffId
		AND status IN ('Approved', 'Pending', 'Completed')
GO