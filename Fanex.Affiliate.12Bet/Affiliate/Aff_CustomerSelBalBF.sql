USE [Affiliate_12BET]
GO

ALTER PROCEDURE [Aff_CustomerSelBalBF]
	@AffID INT,
	@BalBroughtForward MONEY OUTPUT	
AS

/*
	Created: 20090905@Peter
	Task: Select Balance Brought Forward info.
	DB: DBAFF12BET.Affiliate_12Bet

	Revisions:

	Param's Explanation:
		• @custid : Affiliate custid
		• @BalBroughtForward: Commission has transferred and has been approved already.
*/

BEGIN
	SET NOCOUNT ON

	SELECT @BalBroughtForward = dbo.Aff_GetAffBalance(@AffID)	
END
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelBalBF] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelBalBF] TO [vnteam]
GO