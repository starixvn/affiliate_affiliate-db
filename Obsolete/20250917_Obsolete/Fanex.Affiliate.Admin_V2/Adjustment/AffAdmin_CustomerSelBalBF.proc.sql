ALTER Procedure [dbo].[AffAdmin_CustomerSelBalBF]
	@AffID int,
	@Currency varchar(5) = 'USD'
AS

SET NOCOUNT ON

DECLARE @BalBroughtForward money
DECLARE @MaxAmount money	

select @BalBroughtForward = dbo.Aff_GetAffBalance(@AffID)

SET @MaxAmount = (Select SValue
From SystemSettings (nolock)
where SName = 'AFF_MaximumAdjustment' + @Currency)

SELECT @BalBroughtForward As BalBroughtForward,@MaxAmount AS MaxAmount