Alter PROCEDURE [dbo].[Aff_PaymentRequestSelDetail]
	@TransID bigint
AS
/*
 Task : Get All Affiliate for a specific page
DB: DB052.Affiliate_12Bet
Original: [Aff_PaymentRequestSelDetail]
Revisions:   
	- Get Username2 from customer table.
Param's Explanation:
• @TransID : Payment Request's Transaction.
 */
SET NOCOUNT ON
SELECT 
	b.Transid,
	b.AffId,
	b.Transdate,
	b.CompletedDate,
	b.refId,
	b.Status,
	b.Description as transdesc,	
	p.username,
	Replace(isnull(c.Username2, ''), '12bet$', '') as Username2,--Get username2 from customer table
	--af.Player_Username as Username2,	
	af.PreferredPayment,
	af.PreferredLanguage,
	abs(p.Amount) as amt,
	p.AdminDesc,
	p.AffDesc,
	ai.email,
	ai.firstname,
	ai.lastname,
	af.neteller_accountID, 
	af.moneybookers_email, 
	af.wire_bankname, 
	af.wire_bankaddress,
	af.wire_swiftcode,
	af.wire_accountname,
	af.wire_accountno,
	af.Cheque_FullName,
	af.cheque_address,
	af.cheque_city,
	af.cheque_state,
	af.cheque_postal,
	af.cheque_country,
	admin.username as adminname
FROM AffTrans b with(nolock)
	inner join AffPayout p with (nolock) on b.RefId = p.RefId
	inner join AffInfo ai with (nolock) on ai.AffID = b.AffID
	inner join AffDetail af with (nolock) on ai.AffID = af.AffID
	left join Affiliate_User admin with(nolock) on admin.custid=b.creator 	
	left join BODB02.DBO.Customer c with(nolock) on c.custid=p.IBCCustID
WHERE 
	b.Transtype = 202 and b.transid = @transid
	
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestSelDetail] TO [vnteam]
GO
