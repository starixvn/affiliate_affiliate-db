USE [Affiliate_Athena000]
GO

ALTER FUNCTION [dbo].[Aff_GetAffBalance]
(
	@AffID INT
)
RETURNS MONEY
AS

/*
	Created: 20090730@Peter
	Task : Get Balance Brought Forward for Affiliate
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
*/

BEGIN
	DECLARE @BalBroughtForward MONEY

	SELECT  @BalBroughtForward = SUM(Amount)
	FROM dbo.AffTrans WITH(NOLOCK)
	WHERE AffID = @AffId
		AND status IN ('approved','pending','completed')

	RETURN ISNULL(@BalBroughtForward, 0)
END