/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_GetBalBroughtForward]
(
	@AffID INT
)
RETURNS TABLE
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Get Balance Brought Forward for Affiliate by ID
	
	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

*/

RETURN
	SELECT SUM(Amount) AS BalBroughtForward
	FROM dbo.AffTrans WITH (NOLOCK)
	WHERE AffID = @AffId
		AND status IN ('Approved', 'Pending', 'Completed')
GO