/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_GetBalBroughtForward]
(
	@AffID INT
)
RETURNS TABLE
AS

/*
	Created: 20190614@Percy
	DB: DBAFF12BET.Affiliate_12BET
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