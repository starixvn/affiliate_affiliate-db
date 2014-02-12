 ALTER PROCEDURE [dbo].[Aff_DBAFixPaymentRequestCannotApproved]
   @AffUserName varchar(100)
 AS
--DB: DB052.Affiliate_ZZun
SET NOCOUNT ON
Declare @AffID int
select @AffID=affid 
from AffInfo (nolock)
where username= @AffUserName 

if (@AffId is null)
begin
	print 'Invalid affiliate!'
	return
end

--Check table AffPayout for pending request that have problem
if (not exists(select 1 from AffPayout (nolock) where AffID=@AffID and status='pending' and IBCCustID is null))
begin
   print 'Sorry! There is no problem with pending requests for this affiliate'
   return
end

declare @Player_UserName varchar(50), @

select top(10) * from UserLog (nolock) order by LoggedDate desc
where typeid=18

select * from AffInfo (nolock)
where username='12BETAFF1400'

select * from AffDetail (nolock)
where AffID=1726191

select * from AffPayout (nolock) 
where AffID=1185988

select * from AffTrans (nolock)
where AffID=1185988 and transtype=202

select * from Exchange_Current (nolock)
where exchangeid=13

update AffPayout with (rowlock,updlock) 
set AffPayout=-AffPayout
where RefID=100085102303 and AffPayout>0

AffID: 1714391
IBCUserName : 12BETRMB028184
12betusername : ss3636
12bet custid : 43889
Player IBCCustID : 2064014
Mem currency : 13
Created Date (IBC): 2010-01-07 07:29:00

--Update PLayer custID ben AffDetail
--Update IBCCustID,IBCUserName, AffPayout,MemberExRate,MemberCurrency for table AffPayout
-- Update ActualRate ben AffTrans
update dbo.AffDetail with (rowlock,updlock)
set Player_IBCCustID=2064014
where AffID=1714391 

update  dbo.AffPayout with (rowlock,updlock)
set  IBCCustID=2064014,
IBCUserName='12BETRMB028184',
AffPayout=Amount/0.151111111111111,
MemberExRate=0.51,
MemberCurrency=13
where RefID=100085102323 and AffID=1714391 

update  dbo.AffTrans with (rowlock,updlock)
set ActualRate=0.51
 
where RefID=100085102323 and AffID=1714391 


select * from AffPayout (nolock)
 where status='pending' and (IBCCustID is null or IBCUserName is null or AffPayout is null)


select username,refcode2,currency,* from Customer (nolock)
where username2='12bet$ss3636'

select * from rptDepWinlost (nolock) where custid=2064014 order by winlostdate desc

select * from bodb02.dbo.bettrans (nolock) where custid=2064014 and bettype=106

select * from customer (nolock) where username2 ='12bet$1zqcc'

1299105

1187664

--Tim nhung user co Player_IBCCustID khong khop voi Player_UserName va fix no 

select ai.Status,ad.Player_UserName,ad.Player_IBCCustID,c.CustID as custid,ad.* 
from DB052.Affiliate_ZZun.dbo.AffDetail ad with (nolock)
     left join Customer c with (nolock) on c.username2='12bet$' + ad.Player_UserName
     inner join  DB052.Affiliate_ZZun.dbo.AffInfo ai with (nolock) on ai.AffID=ad.AffID
where ad.Player_IBCCustID is null or ad.Player_UserName is null
      or ad.Player_IBCCustID <> c.CustID
      


GO
GRANT EXECUTE ON [dbo].[Aff_DBAFixPaymentRequestCannotApproved] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Aff_DBAFixPaymentRequestCannotApproved] TO [vnAffiliate]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DBAFixPaymentRequestCannotApproved] TO [vnteam]
GO
