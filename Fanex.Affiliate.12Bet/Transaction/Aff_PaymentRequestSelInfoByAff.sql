 ALTER PROCEDURE [dbo].[Aff_PaymentRequestSelInfoByAff]
	@AffID int,
	@PreferredPayment varchar(20) OUTPUT,
	@BalBroughtForward money OUTPUT,	
	@MinAmount money output
AS
/*Created: 20090914@Peter
Task : Getting Payment request history information for Affiliate
DB: DB052.Affiliate_12BET 
Original: [Aff_BettransSelTransfer]
Revisions:
	
Param's Explanation:
• @custid : Affiliate custid
• @BalBroughtForward: Sum(Winlost is transfered and approved to affiliate)
• @PreferredPayment: Preferred Payment method for this affiliate
• @MinAmount
*/		
SET NOCOUNT ON			
Declare @currencyName varchar(5)
Select @PreferredPayment=PreferredPayment
from AffDetail with (nolock)
where AffID=@AffID

SELECT @currencyName = e.currency
from AffInfo a with (nolock)
	 inner join Exchange_Current e with (nolock) on e.ExchangeID=a.currency
where a.AffID=@AffID	
--Get MinAmount value

SELECT @MinAmount = SValue from SystemSettings with(nolock) 
WHERE SName = 'AFF_Min'+ @PreferredPayment + @currencyName

--Get Balance Brought Forward
Select @BalBroughtForward=dbo.Aff_GetAffBalance(@AffID)

--Get list payment request
Select t.TransID,p.RefID, p.TransDate, p.CompletedDate,p.Status,abs(p.Amount) as Amount,p.AffDesc
from AffPayout p with (nolock)
 inner join AffTrans t with (nolock) on t.RefID=p.RefID
where p.AffID=@AffID
order by RefID desc

	
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [vnteam]