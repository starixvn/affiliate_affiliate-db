/*<info serverAlias="DBAFFN8G-Affiliate_N8G" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetBalBroughtForward]
(
	@AffID INT
)
RETURNS TABLE
AS

/*
	Created: 20190614@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Get Balance Brought Forward for Affiliate by ID
	
	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
*/

RETURN
	SELECT SUM(Amount) AS BalBroughtForward
	FROM dbo.AffTrans WITH (NOLOCK)
	WHERE AffID = @AffId
		AND status IN ('Approved', 'Pending', 'Completed')
GO