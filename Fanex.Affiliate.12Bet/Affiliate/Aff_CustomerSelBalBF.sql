ALTER PROCEDURE [Aff_CustomerSelBalBF]
	@AffID int,
	@BalBroughtForward money OUTPUT	
AS
/*
	Created: 20090905@Peter
	Task : Select Balance Brought Forward info.
	DB: DB05.Affiliate_12Bet
	Original: [Aff_CustomerSelBalBF]
	Revisions:
	Param's Explanation:
		• @custid : Affiliate custid
		• @BalBroughtForward: Commission has transferred and has been approved already.
*/
SET NOCOUNT ON


select @BalBroughtForward = dbo.Aff_GetAffBalance(@AffID)	

GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelBalBF] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelBalBF] TO [VNTeam]