/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [Aff_CustomerSelBalBF]
	@AffID INT,
	@BalBroughtForward MONEY OUTPUT	
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Select Balance Brought Forward info

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

	Param's Explanation:
		• @BalBroughtForward: Commission has transferred and has been approved already.
*/

BEGIN
	SET NOCOUNT ON

	SELECT @BalBroughtForward = ISNULL(BalBroughtForward, 0) FROM dbo.Aff_f_GetBalBroughtForward(@AffID)
END
GO 