ALTER PROCEDURE dbo.AffAdmin_GetDefaultPSPExchange
	@CurrencyCode	VARCHAR(10)
AS
/*
*/
BEGIN
	SELECT TOP(1) ex.ExchangeID
		,ex.Code
		,ex.[DepositPercent]
		,ex.[WithdrawalPercent]
	FROM [dbo].[Exchange] ex WITH(NOLOCK)
	WHERE ex.Code = @CurrencyCode
	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetDefaultPSPExchange] TO [bodbAdminNet] AS [dbo]
GO
