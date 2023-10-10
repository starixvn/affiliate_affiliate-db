  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from AffDetail with (nolock))
  begin
      truncate table AffDetail
  end
 

-- AffDetail
insert into AffDetail([AffId],
	   [UserName]
      ,[SiteURL]
      ,[MoreSiteURLs]
      ,[PreferredLanguage]      
      ,[Gender]
      ,[Address]
      ,[Postal]
      ,[City]
      ,[State]
      ,[Country]
      ,[Phone]
      ,[MobilePhone]
      ,[Fax]
      ,[Question]
      ,[Answer]
      ,[PreferredPayment]
      ,[Player_IBCCustID]
      ,[Player_Username]
      ,[Neteller_AccountID]
      ,[Moneybookers_Email]
      ,[Wire_BankName]
      ,[Wire_BankAddress]
      ,[Wire_SwiftCode]
      ,[Wire_AccountName]
      ,[Wire_AccountNo]
      ,[Cheque_FullName]
      ,[Cheque_Address]
      ,[Cheque_City]
      ,[Cheque_State]
      ,[Cheque_Postal]
      ,[Cheque_Country]
      ,[BonusCode]
      ,[LastLoginDate]
      ,[LastLoginIP]
      ,[LoginCount]
      ,[ValidCode]
      ,[CodeExpiry]
      )
select 
	ci.CustID,
	c.Username,
	af.siteurl,
	af.MoreSiteUrls,
	(case af.preferredLanguage 
                             when 'E' then 'en-US' 
                             when 'CS' then 'zh-CN'
                             when 'CT' then 'zh-TW' 
                             when 'ES' then 'es-ES' 
                             when 'TH' then 'th-TH' 
                             when 'VI' then 'vi-VN'
                             when 'ID' then 'id-ID'
                             else 'en-US'
                           end  
                             
                                    ) preferredLanguage,
	c.Gender,
	c.address,
	c.postal,
	c.city,
	c.state,
	c.country,
	c.phone,
	c.mobilephone,
	c.fax,
	af.question,
	af.answer,
	af.preferredPayment,
	p.custid,
	af.Player_Username,
	af.Neteller_AccountID
	,af.Moneybookers_Email
	,af.Wire_BankName
	,af.Wire_BankAddress
	,af.Wire_SwiftCode
	,af.Wire_AccountName
	,af.Wire_AccountNo
	,af.Cheque_FullName
	,af.Cheque_Address
	,af.Cheque_City
	,af.Cheque_State
	,af.Cheque_Postal
	,af.Cheque_Country
	,af.BonusCode
	, c.lastlogged
	,c.iplogin
	,c.logincount
	,c.answer as ValidCode
	,c.question as CodeExpiry
from bodb02.dbo.customer c with (nolock)
	inner join DB03.[12BetAffiliate].dbo.Affiliate_CustInfo af with (nolock) on c.custid = af.custid
	inner join bodb02.dbo.custinfo ci with (nolock) on c.custid = ci.custid
	left join bodb02.dbo.customer p with (nolock) on p.username2 = '12Bet$' + af.player_Username	
where c.mrecommend = (Select top(1) CustID
                      From  bodb02.dbo.customer with (nolock)
                      where username='12BETAFF' 
                     )
         and c.roleid = 2
GO

update AffDetail af with (rowlock,updlock)
Set af.Player_IBCCustID=
    (
       Select CustID 
       from bodb02.dbo.customer p with (nolock)        
       where p.username2 = '12Bet$' + af.player_Username	
    )
where PreferredPayment='Player' and (Player_UserName='' or Player_UserName is null or Player_IBCCustID is null)    

    
