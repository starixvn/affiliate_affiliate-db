USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_PaymentRequestSelInfoByAff]
	@AffID INT,
	@PreferredPayment VARCHAR(20) OUTPUT,
	@BalBroughtForward MONEY OUTPUT,	
	@MinAmount MONEY OUTPUT
AS

/*
	Created: 20090914@Peter
	Task: Getting Payment request history information for Affiliate
	DB: DBAFF12BET.Affiliate_12BET 
	Original: [Aff_BettransSelTransfer]

	Revisions:
	
	Param's Explanation:
		• @custid: Affiliate custid
		• @BalBroughtForward: Sum(Winlost is transfered and approved to affiliate)
		• @PreferredPayment: Preferred Payment method for this affiliate
		• @MinAmount
*/

BEGIN
	SET NOCOUNT ON			
	
	DECLARE @currencyName VARCHAR(5)
	
	SELECT @PreferredPayment = PreferredPayment
	FROM AffDetail WITH(NOLOCK)
	WHERE AffID = @AffID

	SELECT @currencyName = e.currency
	FROM AffInfo a WITH(NOLOCK)
		INNER JOIN Exchange_Current e WITH(NOLOCK) ON e.ExchangeID = a.currency
	WHERE a.AffID=@AffID	
	--Get MinAmount value

	SELECT @MinAmount = SValue
	FROM SystemSettings WITH(NOLOCK)
	WHERE SName = 'AFF_Min'+ @PreferredPayment + @currencyName

	--Get Balance Brought Forward
	SELECT @BalBroughtForward = dbo.Aff_GetAffBalance(@AffID)

	--Get list payment request
	SELECT t.TransID,p.RefID, p.TransDate, p.CompletedDate, p.Status, ABS(p.Amount) AS Amount,p.AffDesc
	FROM AffPayout p WITH(NOLOCK)
		INNER JOIN AffTrans t WITH(NOLOCK) ON t.RefID=p.RefID
	WHERE p.AffID = @AffID
	ORDER BY RefID DESC
END
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [vnteam]
GO