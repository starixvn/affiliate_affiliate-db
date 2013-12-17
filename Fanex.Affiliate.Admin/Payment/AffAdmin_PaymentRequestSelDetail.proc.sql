ALTER Procedure [dbo].[AffAdmin_PaymentRequestSelDetail]  
    @TransID bigint
AS  
/*  
 Task : Get All Affiliate for a specific page  
DB: DB052.Affiliate_MYM  
Original: [Aff_PaymentRequestSelDetail]  
Revisions:     
 - Get Username2 from customer table.  
Param's Explanation:  
• @TransID : Payment Request's Transaction.  
 */  
SET NOCOUNT ON  
  
declare @SystemName varchar(50)  
  
Select @SystemName=SValue  
from SystemSettings with (nolock)  
where SName = 'SystemName' and Type='Meta'  
  
SELECT   
    b.Transid,  
    --smith  
    e.Code as AffCurrency,  
    b.AffId,  
    b.Transdate,  
    b.CompletedDate,  
    b.refId,  
    b.Status,  
    b.Description as transdesc,    
    p.username as UserName2,   
    ai.username as AffUserName,  
    af.PreferredPayment,  
    af.PreferredLanguage,  
    abs(p.Amount) as amt,  
    abs(p.AffPayout) as AffPayout,  
    p.AdminDesc,  
    p.AffDesc,  
    p.AffPayout as TransferAmount,  
    p.IBCUserName,  
    ai.email,  
    ai.firstname,  
    ai.lastname,  
	case when b.Status in ('Pending','Cancelled') and b.TransType=202 then ai.UserName  
                 when b.TransType=201  then 'System'        
         else admin.username  
	end  as  adminname,  
	p.MemberCurrency as PlayerCurrency,   
	@SystemName as SystemName,  
	p.MemberCurrency as Currency,  
	(Select top(1) SValue 
	from SystemSettings with (nolock)  
	where SName ='AFF_BalPlayer'+  e1.Code and Type='Meta'
	) as BalanceUserName,  
	e1.Code as PlayerCurrencyCode  
FROM AffTrans b with(nolock)  
    inner join AffPayout p with (nolock) on b.RefId = p.RefId  
    inner join AffInfo ai with (nolock) on ai.AffID = b.AffID  
    inner join AffDetail af with (nolock) on ai.AffID = af.AffID            
    inner join Exchange e with (nolock) on b.AffCurrency = e.ExchangeID  
    left join Exchange e1 with (nolock) on p.MemberCurrency = e1.ExchangeID  
    left join AdminUser admin with(nolock) on admin.custid=b.creator    
    
WHERE   
    b.Transtype = 202 and b.transid = @transid

GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequestSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_PaymentRequestSelDetail] TO [vnteam]