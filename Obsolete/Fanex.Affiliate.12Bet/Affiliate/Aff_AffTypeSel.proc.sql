ALTER PROCEDURE [dbo].[Aff_AffTypeSel]
AS
/*
Created: @VinhTrinh
Task :
	- Get list afftype
DB: DB052.Affiliate_12Bet
Original: [Aff_AffTypeSel]
Revisions:    
	- 20121030@Johnny: Create
	- 20140226@Bobby: Apply AffType
*/
BEGIN
	SET NOCOUNT ON;

	SELECT TypeId
		,NAME
		,NAME AS TypeName -- backup to old version
		,[Description]
	FROM dbo.AffType WITH (NOLOCK)
END