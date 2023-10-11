  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from MemberInfo with (nolock))
  begin
      truncate table MemberInfo
  end
 
 -- Member Info
INSERT INTO MemberInfo (
	IBCCustID,
	AffID,
	UserName,
	IBCUserName,
	CreatedDate,
	IsRemoved,
	DepositCustID,
	FirstName,
	LastName,
	Currency,
	--Email,
	Recommend
)
SELECT 
	c.custid, 
	affiliateid, 
	right(username2, len(username2)-charindex('$',username2)) as username,
	c.username as IBCUsername, 
	creatdate, 
	0 as IsRemoved,-- IsRemoved
	refcode2, -- DepositCustID
	firstname, 
	lastname,
	c.Currency,
	--c.Email, --Get from Deposit_Customer
	c.Recommend
from bodb02.dbo.customer c with(nolock)
	inner join bodb02.dbo.custinfo ci with(nolock) on c.custid=ci.custid
where ci.recommend in (select aff.custid
					from bodb02.dbo.custinfo aff with (nolock)
					 inner join exchange e with (nolock) on aff.currency=e.exchangeid	 	
					where roleid=2 and 
					      aff.username = '12BET' + e.currency + '02'
					) and ci.roleid=1

GO
--Update RegisteredDate,Email from Deposit_Customer

update mi
set mi.Email=d.email,
    mi.RegisteredDate=d.creatdate
from MemberInfo mi with (rowlock,updlock)
     inner join [DBDeposit].deposit_db.dbo.Deposit_Customer d with (nolock) on d.custid=mi.DepositCustID

Select * from MemberInfo (nolock)

 
