/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetBalBroughtForward]
(
	@AffID INT
)
RETURNS TABLE
AS

/*
	Created: 20190614@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
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