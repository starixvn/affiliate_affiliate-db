/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [Aff_CustomerSelBalBF]
	@AffID INT,
	@BalBroughtForward MONEY OUTPUT	
AS

/*
	Created: 20090905@Peter
	Task: Select Balance Brought Forward info.
	DB: DBAFFN8G-Affiliate_N8G

	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]

	Param's Explanation:
		• @custid : Affiliate custid
		• @BalBroughtForward: Commission has transferred and has been approved already.
*/

BEGIN
	SET NOCOUNT ON

	SELECT @BalBroughtForward = ISNULL(BalBroughtForward, 0) FROM dbo.Aff_f_GetBalBroughtForward(@AffID)
END
GO 