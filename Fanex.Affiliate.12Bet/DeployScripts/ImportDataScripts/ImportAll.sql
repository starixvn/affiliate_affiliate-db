  use Affiliate_12BET
 GO
Truncate table AffDetail
Truncate table AffGroupHistory
Truncate table AffInfo
Truncate table AffPayout
Truncate table AffTrans
Truncate table BankTrans
Truncate table Banners
Truncate table MemberInfo
Truncate table BannerTypes
Truncate table ClickStatistics
Truncate table ClickStatistics_bk
Truncate table ClickStatisticsSum
Truncate table CommGroup
Truncate table CommGroupHistory
Truncate table DeductionSetting
Truncate table DeductionSettingHistory
Truncate table DeductionType
Truncate table EmailHistory
Truncate table Exchange
Truncate table Exchange_Current
Truncate table GroupSetting
Truncate table GroupSettingHistory
Truncate table LogType
Truncate table MemberRemoval
Truncate table News
Truncate table Ref
Truncate table SportType
Truncate table SystemSettings
Truncate table TrackingCode
Truncate table TransType
Truncate table AffCommission
Truncate table AdminFavorite
Truncate table AdminNotes
GO
USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from SportType with (nolock))
  begin
      truncate table SportType
  end

insert into SportType(SportName,QMTurnOver)
select 'SportsBook' as SportName, 100 as QMTurnOver
union all
select 'Horse Racing' as SportName, 100 as QMTurnOver
/*union all
select 'Casino' as SportName, 300 as QMTurnOver*/

GO

if exists (select 1 from DeductionType with (nolock))
  begin
      truncate table DeductionType
  end
  
INSERT INTO [DeductionType]
           ([SportID]
           ,[DTypeName]
           ,[DTypeDesc])
Select dbo.Aff_GetSportID('SportsBook')  as SportID,  'Bonus' as DTypeName,	'Has Bonus for SportsBook' as DTypeDesc  
union all 
Select dbo.Aff_GetSportID('SportsBook')  as SportID,  'Adjustment' as DTypeName,	'Has Adjustment for SportsBook' as DTypeDesc  
union all 
Select dbo.Aff_GetSportID('SportsBook')  as SportID,  'Marketing' as DTypeName,	'Has Marketting fee for SportsBook' as DTypeDesc  
union all 
Select dbo.Aff_GetSportID('SportsBook')  as SportID,  'PSP' as DTypeName,	'Has Payment Solution Package fee for SportsBook' as DTypeDesc  
/*union all 
Select dbo.Aff_GetSportID('Casino')  as SportID,  'Bonus' as DTypeName,	'Has Bonus fee for Casino' as DTypeDesc  
union all 
Select dbo.Aff_GetSportID('Casino')  as SportID,  'Adjustment' as DTypeName,	'Has Adjustment for Casino' as DTypeDesc  
*/
if exists (select 1 from TransType with (nolock))
  begin
      truncate table TransType
  end
  
insert into TransType(TypeID,TypeName,TypeDesc)
select 201 as TypeID,'Commission' as TypeName, 'Affiliate Monthly Transfer'  as TypeDesc
union all
select 202 as TypeID,'Payout' as TypeName, 'Affiliate Payout'  as TypeDesc
union all
select 203 as TypeID,'Adjustment' as TypeName, 'Affiliate Balance Adjustment'  as TypeDesc
union all
select 204 as TypeID,'Marketing' as TypeName, 'Marketing deduction 20% per Affiliate Net Winlost '  as TypeDesc

if exists (select 1 from LogType with (nolock))
  begin
      truncate table LogType
  end

Insert Into LogType(TypeName,Description)
Select 'CommissionGroup' as TypeName,'Setting for Commission Group' as Description
union all
Select 'UserInfo' as TypeName,'User Info' as Description
union all
Select 'Transaction' as TypeName,'Transaction' as Description
union all
Select 'Payout' as TypeName,'Payout' as Description
union all
Select 'Permission' as TypeName,'Permission' as Description
union all
Select 'Player' as TypeName,'Player' as Description
union all
Select 'Banner' as TypeName,'Banner' as Description
union all
Select 'Email' as TypeName,'Email' as Description
union all
Select 'Message' as TypeName,'Message' as Description
union all
Select 'ExchangeRate' as TypeName,'Exchange Rate' as Description
union all
Select 'UserNote' as TypeName,'User Note' as Description
union all
Select 'LoginAdmin' as TypeName,'Login Admin' as Description
union all
Select 'LoginAffiliate' as TypeName,'Login Affiliate' as Description
union all
Select 'LogoutAdmin' as TypeName,'Logout Admin' as Description
union all
Select 'LogoutAffiliate' as TypeName,'Logout Affiliate' as Description
union all
Select 'Password' as TypeName,'Password' as Description
union all
Select 'Adjustment' as TypeName,'Adjustment' as Description
union all
Select 'Member' as TypeName,'Member' as Description
union all
Select 'UserControl' as TypeName,'User Control' as Description
  
  
if exists (select 1 from Ref with (nolock))
  begin
      truncate table Ref
  end  
Insert into Ref(RefName,RefNo)
Select 'AFF_Adj' as RefName,3000000000 as RefNo
union all
Select 'AFF_Comm' as RefName,100000000 as RefNo  
union all
Select 'Log' as RefName,10000000 as RefNo  
union all
Select 'Trans' as RefName,2000000000000 as RefNo  

if exists (select 1 from SystemSettings with (nolock))
  begin
      truncate table SystemSettings
  end 
  
Insert into SystemSettings(SName,SValue)
Select 'AFF_BalWireUS$' as SName, '12BETAFFMBankUS$' as SValue
union all  
Select 'AFF_BalNetellerUS$' as SName, '12BETAFFNetellerUS$' as SValue
union all  
Select 'AFF_BalChequeUS$' as SName, '12BETAFFChequeUS$' as SValue
union all  
Select 'AFF_BalMoneybookersUS$' as SName, '12BETAFFMBookersUS$' as SValue
union all  
Select 'AFF_BalWireUUS' as SName, '12BETAFFMBankUUS' as SValue
union all  
Select 'AFF_BalNetellerUUS' as SName, '12BETAFFNetellerUUS' as SValue
union all  
Select 'AFF_BalChequeUUS' as SName, '12BETAFFChequeUUS' as SValue
union all  
Select 'AFF_BalMoneybookersUUS' as SName, '12BETAFFMBookersUUS' as SValue
union all  
Select 'AFF_MinWireUS$' as SName, '100' as SValue
union all  
Select 'AFF_MinNetellerUS$' as SName, '100' as SValue
union all  
Select 'AFF_MinChequeUS$' as SName, '100' as SValue
union all  
Select 'AFF_MinMoneybookersUS$' as SName, '100' as SValue
union all  
Select 'AFF_MinWireUUS' as SName, '100' as SValue
union all  
Select 'AFF_MinNetellerUUS' as SName, '100' as SValue
union all  
Select 'AFF_MinChequeUUS' as SName, '100' as SValue
union all  
Select 'AFF_MinMoneybookersUUS' as SName, '100' as SValue
union all  
Select 'AFF_MinPlayerUS$' as SName, '100' as SValue
union all  
Select 'AFF_MinPlayerUUS' as SName, '10' as SValue
union all  
Select 'AFF_BalPlayerTB' as SName, '12BETAFFPlayerTB' as SValue
union all  
Select 'AFF_BalPlayerUS$' as SName, '12BETAFFPlayerUS$' as SValue
union all  
Select 'AFF_BalPlayerEURO' as SName, '12BETAFFPlayerEURO' as SValue
union all  
Select 'AFF_BalPlayerGBP' as SName, '12BETAFFPlayerGBP' as SValue
union all  
Select 'AFF_BalPlayerRM' as SName, '12BETAFFPlayerRM' as SValue
union all  
Select 'AFF_BalPlayerRMB' as SName, '12BETAFFPlayerRMB' as SValue
union all  
Select 'AFF_BalPlayerAUD' as SName, '12BETAFFPlayerAUD' as SValue
union all  
Select 'AFF_BalPlayerCHF' as SName, '12BETAFFPlayerCHF' as SValue
union all  
Select 'AFF_BalPlayerUUS' as SName, '12BETAFFPlayerUUS' as SValue
union all  
Select 'AFF_BalPlayerSD$' as SName, '12BETAFFPlayerSD$' as SValue
union all  
Select 'AFF_SupportedCurrencies' as SName, 'TB;US$;EURO;GBP;RM;RMB;AUD;CHF;SD$;IN;UUS' as SValue
union all  
Select 'AFF_BalPlayerIN' as SName, '12BETAFFPlayerIN' as SValue
union all
Select 'AFF_OldReportDate' as SName, '31 Oct 2009' as SValue

--Add Default commission group from website

if exists (select 1 from CommGroup with (nolock))
  begin
      truncate table CommGroup
  end 
  
INSERT INTO [Affiliate_12BET].[dbo].[CommGroup]
           ([GroupID]
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description])
Select  101 as [GroupID]
        ,'Default' as [GroupName]
        ,current_timestamp as[CreatedDate]
        ,1155577 as [Creator]
        ,0 as [IsDeleted]
        ,'Default System Commission Group' [Description]          
union all
Select  102 as [GroupID]
        ,'NoCommission' as [GroupName]
        ,current_timestamp as[CreatedDate]
        ,1155577 as [Creator]
        ,0 as [IsDeleted]
        ,'Group for all zero commission/closed affiliates' [Description]          


if exists (select 1 from GroupSetting with (nolock))
  begin
      truncate table GroupSetting
  end 
  
INSERT INTO [Affiliate_12BET].[dbo].[GroupSetting]
           ([GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission])
Select 101 as [GroupID]
        ,dbo.Aff_GetSportID('SportsBook') as SportType 
        ,1 as [TierID]
        ,0 as [MinAmount]
        ,0 as [MaxAmount]
        ,0 as [MinQM]
        ,4 as [MaxQM]
        ,0 as [Commission]
union all
Select 101 as [GroupID]
        ,dbo.Aff_GetSportID('SportsBook') as SportType 
        ,2 as [TierID]
        ,1 as [MinAmount]
        ,399 as [MaxAmount]
        ,5 as [MinQM]
        ,9 as [MaxQM]
        ,0.10 as [Commission]
union all
Select 101 as [GroupID]
        ,dbo.Aff_GetSportID('SportsBook') as SportType 
        ,3 as [TierID]
        ,400 as [MinAmount]
        ,49999 as [MaxAmount]
        ,10 as [MinQM]
        ,50 as [MaxQM]
        ,0.20 as [Commission]

union all
Select 101 as [GroupID]
        ,dbo.Aff_GetSportID('SportsBook') as SportType 
        ,4 as [TierID]
        ,50000 as [MinAmount]
        ,99999 as [MaxAmount]
        ,51 as [MinQM]
        ,200 as [MaxQM]
        ,0.30 as [Commission]
union all
Select 101 as [GroupID]
        ,dbo.Aff_GetSportID('SportsBook') as SportType 
        ,5 as [TierID]
        ,100000 as [MinAmount]
        ,149999 as [MaxAmount]
        ,201 as [MinQM]
        ,250 as [MaxQM]
        ,0.40 as [Commission]
union all
Select 101 as [GroupID]
        ,dbo.Aff_GetSportID('SportsBook') as SportType 
        ,6 as [TierID]
        ,150000 as [MinAmount]
        ,100000000000000 as [MaxAmount]
        ,251 as [MinQM]
        ,1000000000 as [MaxQM]
        ,0.50 as [Commission]
union all
Select 102 as [GroupID]
        ,dbo.Aff_GetSportID('SportsBook') as SportType 
        ,1 as [TierID]
        ,0 as [MinAmount]
        ,100000000000000 as [MaxAmount]
        ,0 as [MinQM]
        ,1000000000 as [MaxQM]
        ,0.00 as [Commission]

  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from News with (nolock))
  begin
      truncate table News
  end
  
-- News
SET IDENTITY_INSERT News ON
GO
INSERT INTO News (
	MsgID,
	Message_en,
	Message_cn,
	Message_tw,
	Message_th,
	Message_es,
	Message_id,
	Message_vi,
	Creator,
	PostedDate,
	Important,
	UpdatedBy,
	UpdatedDate
)
SELECT 
	MsgID,
	Message_en,
	Message_cn,
	Message_tw,
	Message_th,
	Message_es,
	Message_id,
	Message_vi,
	Creator,
	PostDate,
	Important,
	UpdatedBy,
	UpdateDate
from DB03.[12BetAffiliate].dbo.Affiliate_News with(nolock)	
GO
SET IDENTITY_INSERT News OFF
GO	

  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from Exchange_Current with (nolock))
  begin
      truncate table Exchange_Current
  end
  
-- Exchange_Current
INSERT INTO Exchange_Current (
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
)
SELECT 
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
from DB03.[12BetAffiliate].dbo.Affiliate_Exchange_Current with(nolock)
GO
  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from Exchange with (nolock))
  begin
      truncate table Exchange
  end
  
  -- Exchange
INSERT INTO Exchange (
	UpdatedTime,
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
)
SELECT 
	UpdateTime,
	ExchangeID,
	Currency,
	ActualRate,
	ActualRate2,
	Creator
from DB03.[12BetAffiliate].dbo.Affiliate_Exchange with (nolock)
GO
  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from EmailHistory with (nolock))
  begin
      truncate table EmailHistory
  end
  
-- EmailHistory
SET IDENTITY_INSERT EmailHistory ON
GO
INSERT INTO EmailHistory (
	MID,
	Content,
	Sender,
	Creator,
	AffId,
	AffName,
	Email,
	Subject,
	CreatedDate,
	IP,
	Browser,
	SessionID
)
SELECT 
	MID,
	Content,
	Sender,
	Creator,
	AffiliateId,
	AffName,
	Email,
	Subject,
	CreateDate,
	IP,
	Browser,
	SessionID
from DB03.[12BetAffiliate].dbo.Affiliate_EmailHistory with (nolock)	
GO
SET IDENTITY_INSERT EmailHistory OFF
GO	
  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from Banners with (nolock))
  begin
      truncate table Banners
  end
  
-- Banners
SET IDENTITY_INSERT Banners ON
GO
INSERT INTO Banners (
	BannerID,
	FileName,
	Category,
	Language,
	ImageType,
	Size,
	LastUpdate,
	Currency,
	CreatedDate,
	UpdatedBy,
	Creator
)
SELECT 
	BannerID,
	FileName,
	Category,
	Language,
	ImageType,
	Size,
	LastUpdate,
	Currency,
	CreateDate,
	UpdatedBy,
	Creator
from DB03.[12BetAffiliate].dbo.Affiliate_banners	
GO
SET IDENTITY_INSERT Banners OFF
GO	
   USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from BannerTypes with (nolock))
  begin
      truncate table BannerTypes
  end
  
-- BannerTypes
INSERT INTO BannerTypes (
	Type,
	Value,
	DisplayOrder
)
SELECT 
	Type,
	Value,
	DisplayOrder
from DB03.[12BetAffiliate].dbo.Affiliate_BannerTypes	
GO

Select * from BannerTypes
 USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from AdminNotes with (nolock))
  begin
      truncate table AdminNotes
  end
  
-- AdminNotes
SET IDENTITY_INSERT AdminNotes ON
GO
INSERT INTO AdminNotes (
	NoteID,
	Note,
	UpdatedDate,
	AffID,
	UpdatedBy
)
SELECT 
	NoteID,
	Note,
	UpdateDate,
	CustID,
	UpdatedBy
from DB03.[12BetAffiliate].dbo.Affiliate_Note with (nolock)	
GO
SET IDENTITY_INSERT AdminNotes OFF
GO	  
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

   USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from AffInfo with (nolock))
  begin
      truncate table AffInfo
  end
 

-- AffTrans
set identity_insert AffInfo on
GO
insert into AffInfo(
	  [AffID]
	  ,[UserName]
      ,[UserName2]      
	  ,[FirstName]
      ,[LastName]      
      ,[Status]
      ,[ApprovedDate]
      ,[IsClosed]
      ,[Currency]
      ,[RegisteredDate]
      ,[Email]
      ,[Password]
      ,[AffType]
      )
select
	c.CustId,
	c.Username,
	null as Username2,	
	c.FirstName,
	c.LastName,	
	af.status,
	af.ApprovalDate,
	ci.closed,
	c.currency,
	c.creatdate,
	c.email,
	c.userpwd,
	1 as AffType	
from bodb02.dbo.customer c with (nolock)
	inner join DB03.[12BetAffiliate].dbo.Affiliate_CustInfo af with (nolock) on c.custid = af.custid
	inner join bodb02.dbo.custinfo ci with (nolock) on c.custid = ci.custid	
where c.mrecommend = (Select top(1) CustID
                      From  bodb02.dbo.customer with (nolock)
                      where username='12BETAFF' 
                     )
      and c.roleid = 2
GO
set identity_insert AffInfo off
GO

--Assign Commission Group for Affiliate
declare @MaxGroupID int
select @MaxGroupID=max(groupid)
from CommGroup with (nolock)
select @MaxGroupID=coalesce(@MaxGroupID,102)
if @MaxGroupID<102
 select @MaxGroupID=102

declare @CommGroup table (apositiontaking float,groupid int IDENTITY(1,1),GroupName nvarchar(100), CreatedDate datetime,Creator int,IsDeleted bit,Description nvarchar(100))
 Declare @GroupSetting table(groupid int,sporttype int,tierID int,MinAmount money,MaxAmount money,MinQM int,MaxQM int,Commission decimal(9,8))
 
 Insert Into @CommGroup(apositiontaking,GroupName,CreatedDate,Creator,IsDeleted,Description)
 Select distinct cs.apositiontaking,'CommGroup' + left(cast(floor(cs.apositiontaking * 100) as varchar(20)),2) as GroupName,current_timestamp,148,0,'Group for converting data'
  from bodb02.dbo.custsetting cs with(nolock) 
      inner join AffInfo ai with (nolock) on ai.AffID=cs.CustID
WHERE sporttype = 1 
	AND bettype = 1 
	AND cs.apositiontaking<>0
	
	
declare @SportsBookID int,@HRSportID int

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HRSportID=dbo.Aff_GetSportID('Horse Racing')
	
	
Insert into @GroupSetting(groupid,sporttype,tierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
Select groupid + @MaxGroupID,@SportsBookID as SportType,1,0,100000000000000,0,1000000000,apositiontaking
from @CommGroup
union all
Select  groupid + @MaxGroupID,@HRSportID as SportType,1,0,100000000000000,0,1000000000,0
from @CommGroup

Delete GroupSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'CommGroup%')

Delete DeductionSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'CommGroup%')

Delete CommGroup
where GroupName like 'CommGroup%'

INSERT INTO [Affiliate_12BET].[dbo].[CommGroup]
           ([GroupID]
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description])
Select  [GroupID] + @MaxGroupID
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description]
          
From @CommGroup

INSERT INTO [Affiliate_12BET].[dbo].[DeductionSetting]
           ([GroupID]
           ,[DeductionID]
          )

select  [GroupID] + @MaxGroupID,1 
From @CommGroup


INSERT INTO [Affiliate_12BET].[dbo].[GroupSetting]
           ([GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission])
Select [GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission]
From  @GroupSetting 

declare @NoCommGroupID int
select @NoCommGroupID=GroupID 
from CommGroup with (nolock)
where GroupName='NoCommission'


update ai
   set ai.GroupID=( case when cs.apositiontaking=0 then @NoCommGroupID
                          else (select groupid + @MaxGroupID
                                from @CommGroup
                                where GroupName='CommGroup' + left(cast(floor(cs.apositiontaking * 100) as varchar(20)),2) )
                      end
                 )   
from AffInfo ai with (rowlock,updlock)
     inner join bodb02.dbo.custsetting cs with(nolock) on cs.custid= ai.AffID and cs.sporttype = 1 
	AND cs.bettype = 1 	
where ai.Status='Approved'	
	
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

  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from BankTrans with (nolock))
  begin
      truncate table BankTrans
  end
  
 INSERT INTO [Affiliate_12BET].[dbo].[BankTrans]
           ([TransID]
           ,[CustID]
           ,[Bettype]
           ,[TransDate]
           ,[Remark]
           ,[CreditAffected]
           ,[AffTransFee]
           ,[OurTransFee]
           ,[PreferredPayment]
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
           ,[CompletedDate])
  SELECT [TransID]
      ,[CustID]
      ,[Bettype]
      ,[TransDate]
      ,[Remark]
      ,[CreditAffected]
      ,[AffTransFee]
      ,[OurTransFee]
      ,[PreferredPayment]
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
      ,[CompletedDate]
  FROM DB03.[12BetAffiliate].[dbo].[Affiliate_BankTrans] with (nolock)   

Select * from BankTrans
 
USE [Affiliate_12BET]

SET NOCOUNT ON
GO
declare @FromDate smalldatetime,@ToDate smalldatetime ,@HRWinlostDate smalldatetime
select @FromDate='01 Oct 2009' --min (winlostdate) from DB06.bodb_report.dbo.rptDepWinlost r with(nolock)

select @ToDate = '31 Oct 2009',@HRWinlostDate='2009-07-14 00:00:00'

if(@FromDate>@ToDate)
   return
if(@HRWinlostDate<@FromDate)
  select @HRWinlostDate=@FromDate

if exists (select 1 from MemberDaily with (nolock) WHERE winlostdate between @FromDate and @ToDate )
  begin
      DELETE FROM MemberDaily WHERE winlostdate between @FromDate and @ToDate
end
  
declare @SportsBookID int,@HorseRacingID int
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')



--Insert SportsBook

INSERT INTO MemberDaily(
	WinlostDate,
	IBCCustID,
	Sporttype,
	Currency,
	Deposit,
	Withdrawal,	
	Bonus,
	Adjustment,
	Turnover,
	Outstanding,
	Winlost,
	AWinlost,
    ABonus,
	AffExRate,
	MemberExRate,	
	DrawGame,
	PSP,
	Marketing,
    AffID
)

SELECT 
	r.WinlostDate,
	m.IBCCustID, 
	@SportsBookID as SportType, --sporttype	
	m.currency,
	Deposit, 
	Withdrawal, 	
	Bonus, 
	Adjustment, 
	r.Turnover, 
	r.Outstanding, 
	Winloss, 
	aWinlost,
    aBonus,
	aExRate, 
	actualrate,	
	r.DrawGame, 
	0 as PSP,
	0 as Marketing,
    m.AffID
FROM DB06.bodb_report.dbo.rptDepWinlost r with(nolock)	
	inner join MemberInfo m with (nolock) on r.CustID = m.IBCCustID	
WHERE WinlostDate between @FromDate and @ToDate 

--Insert Horse Racing rows . Recalculate old data

CREATE TABLE #Data(
	IBCCustID int,     	
    WinlostDate smalldatetime,
    Currency int,
	TurnOver money,
	Outstanding money,
    Winlost money,
    DrawGame money,      
    AffExRate float,
    MemberExRate float,        
    AffID int
)
insert into #Data(IBCCustID,	
    WinlostDate,
    Currency,
	TurnOver,
	Outstanding,
    Winlost,
    DrawGame,   
    MemberExRate,   
    AffExRate,            
    AffID
)
select b.custid, 
       b.WinlostDate,
        b.Currency, 
        isnull(sum(isnull(stake,0)),0) as TurnoverHR,
        0 as OutstandingHR,
        isnull(sum(isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0)),0) as WinlostHR,
		isnull(sum(case when status in ('DRAW') then isnull(stake,0) else 0 end),0) as DrawGameHR,
		e.ActualRate,
		e.ActualRate2,
		m.AffID
from DB06.bodb_archive.dbo.bettrans_bk b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @HRWinlostDate and @ToDate
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')
		      and ruben=1
		group by b.custid ,
		         b.winlostdate,
		         b.currency,
                e.ActualRate2,
                e.ActualRate,
                m.AffID   		 		
				
union all
 select b.custid,  
        b.WinlostDate,
        b.Currency, 
        isnull(sum(isnull(stake,0)),0) as TurnoverHR,
        0 as OutstandingHR,
        isnull(sum(isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0)),0) as WinlostHR,
		isnull(sum(case when status in ('DRAW') then isnull(stake,0) else 0 end),0) as DrawGameHR,
		e.ActualRate,
		e.ActualRate2,
		m.AffID
from bodb02.dbo.bettrans14 b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @HRWinlostDate and @ToDate
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')
		      and ruben=1
		group by b.custid ,
		         b.winlostdate,
		         b.currency,
                e.ActualRate2,
                e.ActualRate,
                m.AffID   	
union all
  select b.custid,   
        b.WinlostDate,
        b.Currency, 
        isnull(sum(isnull(stake,0)),0) as TurnoverHR,
		isnull(sum(case when ruben=0 then isnull(actual_stake,0) else 0 end),0) as OutstandingHR,
		isnull(sum(case when ruben=1 then isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0) else 0 end),0) as WinlostHR,
		isnull(sum(case when status in ('DRAW') then isnull(stake,0) else 0 end),0) as DrawGameHR,
		e.ActualRate,
		e.ActualRate2,
		m.AffID
from bodb02.dbo.bettrans b with (nolock)		
	INNER JOIN MemberInfo m with(nolock) on b.custid = m.IBCCustID
     INNER JOIN Exchange e with (nolock) on e.ExchangeID=b.currency and datediff(mm,winlostdate,e.UpdatedTime)=0
		where winlostdate between @HRWinlostDate and @ToDate
		      and bettype in (31,32,33,41,42,43)
		      and status not in ('VOID', 'REJECT', 'REFUND','DONE')		      
		group by b.custid ,
		         b.winlostdate,
		         b.currency,
                e.ActualRate2,
                e.ActualRate,
                m.AffID   	
select * from #Data with (nolock)

 
INSERT INTO MemberDaily(
	WinlostDate,
	IBCCustID,
	Sporttype,
	Currency,
	Deposit,
	Withdrawal,	
	Bonus,
	Adjustment,
	Turnover,
	Outstanding,
	Winlost,
	AWinlost,
    ABonus, 
	AffExRate,
	MemberExRate,	
	DrawGame,
	PSP,
	Marketing,
    AffID
)

SELECT 
	r.WinlostDate,
	r.IBCCustID, 
	@HorseRacingID as SportType, --sporttype	
	r.currency,
	0 as Deposit, 
	0 as Withdrawal, 	
	0 as Bonus, 
	0 as Adjustment, 
	r.Turnover,
	r.Outstanding, 
	r.Winlost, 
	0 as AWinlost,
    0 as ABonus,
	r.AffExRate,
    r.MemberExRate,
	r.DrawGame, 
	0 as PSP,
	0 as Marketing,
    r.AffID    			
FROM #Data r with(nolock)	
 where (winlost<>0 or Turnover<>0 or DrawGame<>0 or Outstanding<>0)

drop table #Data

--Reupdate SportsBook =SportsBook-HorseRacing
Update d
set d.Turnover=d.Turnover-isnull(d1.Turnover,0),
	d.Outstanding=d.Outstanding-isnull(d1.Outstanding,0), 
	d.Winlost=d.Winlost-isnull(d1.Winlost,0), 
    d.DrawGame=d.DrawGame-isnull(d1.DrawGame,0)
from MemberDaily d   with (rowlock,updlock)
     left join MemberDaily d1 with (nolock) on d1.IBCCustID=d.IBCCustID and d1.WinlostDate=d.WinlostDate and d1.SportType=@HorseRacingID
where d.SportType=@SportsBookID and d.Winlostdate between @HRWinlostDate and @ToDate	

update t 
set  t.AWinlost=coalesce(AWinlost,0),
    t.ABonus= coalesce(ABonus,0),
    t.MemberExRate=coalesce(t.MemberExRate,e.ActualRate),
    t.AffExRate=coalesce(t.AffExRate,e.ActualRate2)
from MemberDaily t with (rowlock,updlock)
     inner join Exchange e with (nolock) on e.ExchangeID=t.Currency and datediff(m,e.UpdatedTime,t.WinlostDate)=0
where t.winlostdate between @FromDate and @ToDate 
    and t.AffExRate is null or t.MemberExRate is null or t.AWinlost is null or t.ABonus is null

USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if (not exists (select 1 from AffTrans with (nolock)) )
begin
	truncate table AffTrans
end

if exists (select 1 from AffTrans with (nolock) where TransType=203)
  begin
      Delete AffTrans where TransType=203
  end
  
 -- AffInfo
set identity_insert AffTrans on
GO 
  INSERT INTO [AffTrans]
           ([TransID]
            ,[AffID]
           ,[TransDate]
           ,[CompletedDate]
           ,[Amount]
           ,[Status]
           ,[Description]
           ,[Creator]
           ,[Currency]
           ,[ActualRate]
           ,[TransType]
           ,[RefID]
           ,[AffExRate])
  SELECT b.[TransID]
      ,b.[CustID]
      ,[TransDate]
      ,[CompletedDate]
      ,isnull([Winlost],0)-isnull([Actual_Stake],0) as Amount
      ,'Completed' as Status      
      ,[Description]
      ,[Creator]
      ,ai.currency
      ,[IbcExRate_Aff]
      , 203 --Adjustment
      ,RefNo
      ,[IbcExRate_Aff]   
  FROM DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock)
       left join AffInfo ai with (nolock) on ai.AffID=b.custid
  where bettype=103          
GO
set identity_insert AffTrans off
GO  

 --Check whether still have a pending request -->if yes--> raise an error
 
 /* Rejected tickets:
   still insert 1 row into AffTrans
   to AffCommission : AffWinlost will equal to 0
   each months will have commission groups equal to apositiontaking
   */
  
USE [Affiliate_12BET]

SET NOCOUNT ON
GO
/*if (exists (select 1 from DB03.[12BetAffiliate].dbo.Affiliate_Bettrans with (nolock) where Status='Pending'))
begin
	select 'Oops, still have some pending requests on old data. Cannot convert! Please check. '
	return
end*/
if (not exists (select 1 from AffTrans with (nolock)) )
begin
	truncate table AffTrans
end

if exists (select 1 from AffTrans with (nolock) where TransType=201)
  begin
      Delete AffTrans where TransType=201
  end
 
--AffCommision
if (exists (select 1 from AffCommission with (nolock)) )
begin
	truncate table AffCommission
end

--Create a commision group history and assign commission group history for affiliate from apositiontaking
 /*This commission group must be have IsDeleted=1  and GroupName='OldGroup[apositiontaking]', GroupID=103,104,.... */
 declare @MaxGroupID int
select @MaxGroupID=max(groupid)
from CommGroup with (nolock)
select @MaxGroupID=coalesce(@MaxGroupID,102)
if @MaxGroupID<102
 select @MaxGroupID=102
 
 declare @CommGroup table (apositiontaking float,groupid int IDENTITY(1,1),GroupName nvarchar(100), CreatedDate datetime,Creator int,IsDeleted bit,Description nvarchar(100))
 Declare @GroupSetting table(groupid int,sporttype int,tierID int,MinAmount money,MaxAmount money,MinQM int,MaxQM int,Commission decimal(9,8))
 
 Insert Into @CommGroup(apositiontaking,GroupName,CreatedDate,Creator,IsDeleted,Description)
 Select distinct cs.apositiontaking,'OldGroup' + left(cast(floor(cs.apositiontaking * 100) as varchar(20)),2) as GroupName,current_timestamp,148,1,'Old Group for converting data'
  from bodb02.dbo.custsetting cs with(nolock) 
      inner join AffInfo ai with (nolock) on ai.AffID=cs.CustID
WHERE sporttype = 1 
	AND bettype = 1 
	
	
declare @SportsBookID int,@HRSportID int

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HRSportID=dbo.Aff_GetSportID('Horse Racing')
	
	
Insert into @GroupSetting(groupid,sporttype,tierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
Select groupid + @MaxGroupID,@SportsBookID as SportType,1,0,100000000000000,0,1000000000,apositiontaking
from @CommGroup
union all
Select groupid + @MaxGroupID,@HRSportID as SportType,1,0,100000000000000,0,1000000000,0
from @CommGroup

Delete GroupSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'OldGroup%')

Delete DeductionSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'OldGroup%')

Delete CommGroup
where GroupName like 'OldGroup%'

INSERT INTO [Affiliate_12BET].[dbo].[CommGroup]
           ([GroupID]
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description])
Select  [GroupID] + @MaxGroupID
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description]
          
From @CommGroup

INSERT INTO [Affiliate_12BET].[dbo].[DeductionSetting]
           ([GroupID]
           ,[DeductionID]
          )

select  [GroupID] + @MaxGroupID,1 
From @CommGroup

INSERT INTO [Affiliate_12BET].[dbo].[GroupSetting]
           ([GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission])
Select [GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission]
From  @GroupSetting                     
                     
                      

INSERT INTO [Affiliate_12BET].[dbo].[AffCommission]
           ([RelNo]
           ,[AffID]
           ,[GroupID]
           ,[SportID]
           ,[WinlostDate]
           ,[QualifiedMember]
           ,[Commission]
           ,[HasBonus]
           ,[HasAdjustment]
           ,[HasMarketing]
           ,[HasPSP]
           ,[AffWinlost]
           ,[Status]
           ,[MemberWinlost]
           ,[MemberBonus]
           ,[MemberAdjustment]
           ,[MemberPSP]
           ,[MemberSum]
           ,[MemberTurnover]
           ,[MemberDeposit] 
           ,[Marketing])

  SELECT b.[TransID]
      ,b.[CustID]
      ,g.GroupID + @MaxGroupID
      ,@SportsBookID as SportID
      ,b.WinlostDate
      ,b.[QualifiedMember]
      ,cs.apositiontaking
      ,1 as HasBonus
      ,0 as HasAdjustment
      ,0 as HasMarketing
      ,0 as HasPSP
      ,isnull(b.Winlost,0)-isnull(b.Actual_Stake,0) as AffWinlost
      ,b.[Status]
      ,0 as MemberWinlost
      ,0 as MemberBonus
      ,0 as MemberAdjustment
      ,0 as MemberPSP
      ,0 as MemberSum
      ,0
      ,0
      ,0 as Marketing      
  FROM DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock)
       left join bodb02.dbo.custsetting cs with(nolock) on cs.CustID=b.custid and cs.sporttype = 1 AND cs.bettype = 1 
       inner join @CommGroup g on g.apositiontaking=cs.apositiontaking
  where b.bettype=105     
  
  update t
  set t.MemberWinlost =isnull(m.winlost,0),
       t.MemberBonus  =isnull(m.bonus,0),
       t.MemberAdjustment=isnull(m.Adjustment,0),
       t.MemberPSP=isnull(m.PSP,0),
       t.Marketing=isnull(m.Marketing,0),
       t.MemberTurnover=isnull(m.Turnover,0),   
       t.MemberDeposit=isnull(m.Deposit,0),   
       t.MemberSum=isnull(m.winlost,0) + isnull(m.bonus,0)
   from  AffCommission t with (rowlock,updlock)

         inner join 
              (
                select 
                       a.AffID as AffID,
                       a.WinlostDate as WinlostDate,
                       a.SportID as SportID,
                       sum(isnull(m1.winlost,0) * isnull(m1.AffExRate,0)) as winlost,
                       sum(isnull(m1.bonus,0)* isnull(m1.AffExRate,0)) as bonus,
                       sum(isnull(m1.Adjustment,0)* isnull(m1.AffExRate,0)) as Adjustment,
                       sum(isnull(m1.Turnover,0)* isnull(m1.AffExRate,0)) as Turnover,
                       sum(isnull(m1.Deposit,0)* isnull(m1.AffExRate,0)) as Deposit,
                       sum(isnull(m1.PSP,0)* isnull(m1.AffExRate,0)) as PSP,
                       sum(isnull(m1.Marketing,0)* isnull(m1.AffExRate,0)) as Marketing 
                 from MemberDaily m1 with (nolock) 
                    inner join AffCommission a with(nolock) on m1.AffID=a.AffID and  m1.SportType=a.SportID 
                  where datediff(m,m1.winlostdate,a.winlostdate)=0   
                  group by a.AffID,a.WinlostDate,a.SportID 
              ) m  on m.AffID=t.AffID and  m.SportID=t.SportID and m.WinlostDate=t.WinlostDate



--delete AffCommission where SportID=2
INSERT INTO [Affiliate_12BET].[dbo].[AffCommission]
           ([RelNo]
           ,[AffID]
           ,[GroupID]
           ,[SportID]
           ,[WinlostDate]
           ,[QualifiedMember]
           ,[Commission]
           ,[HasBonus]
           ,[HasAdjustment]
           ,[HasMarketing]
           ,[HasPSP]
           ,[AffWinlost]
           ,[Status]
           ,[MemberWinlost]
           ,[MemberBonus]
           ,[MemberAdjustment]
           ,[MemberPSP]
           ,[MemberSum]
           ,[MemberTurnover]
           ,[MemberDeposit]
           ,[Marketing])
 select    ac.[RefID]
           ,ac.[AffID]
           ,ac.[GroupID]
           ,@HRSportID as SportID
           ,ac.[WinlostDate]
           ,0 as [QualifiedMember]
           ,0 as [Commission]
           ,0 as [HasBonus]
           ,0 as [HasAdjustment]
           ,0 as [HasMarketing]
           ,0 as [HasPSP]
           ,0 as [AffWinlost]
           ,ac.[Status]
           ,isnull(t.winlost,0)
           ,isnull(t.bonus,0)
           ,isnull(t.Adjustment,0)
           ,isnull(t.PSP,0)
           ,isnull(t.winlost,0) + isnull(t.bonus,0) as MemberSum
           ,isnull(t.Turnover,0)
           ,isnull(t.Deposit,0)
           ,isnull(t.Marketing,0)   
from AffCommission ac with (nolock)
    inner join 
              (
                select 
                       a.AffID as AffID,
                       a.WinlostDate as WinlostDate,                       
                       sum(isnull(m1.winlost,0) * isnull(m1.AffExRate,0)) as winlost,
                       sum(isnull(m1.bonus,0)* isnull(m1.AffExRate,0)) as bonus,
                       sum(isnull(m1.Adjustment,0)* isnull(m1.AffExRate,0)) as Adjustment,
                       sum(isnull(m1.Turnover,0)* isnull(m1.AffExRate,0)) as Turnover,
                       sum(isnull(m1.Deposit,0)* isnull(m1.AffExRate,0)) as Deposit,
                       sum(isnull(m1.PSP,0)* isnull(m1.AffExRate,0)) as PSP,
                       sum(isnull(m1.Marketing,0)* isnull(m1.AffExRate,0)) as Marketing 
                 from MemberDaily m1 with (nolock) 
                    inner join AffCommission a with(nolock) on m1.AffID=a.AffID 
                  where datediff(m,m1.winlostdate,a.winlostdate)=0  and m1.SportType=@HRSportID
                  group by a.AffID,a.WinlostDate
              ) t  on t.AffID=ac.AffID and  t.WinlostDate=ac.WinlostDate
              
              
 -- AffPayout
set identity_insert AffTrans on
GO 
    INSERT INTO AffTrans
           ([TransID]
            ,[AffID]
           ,[TransDate]
           ,[CompletedDate]
           ,[Amount]
           ,[Status]
           ,[Description]
           ,[Creator]
           ,[Currency]
           ,[ActualRate]
           ,[TransType]
           ,[RefID]
           ,[AffExRate])
    SELECT 
       b.TransID
      ,ac.[AffID]
      ,ac.WinlostDate
      ,b.CompletedDate
      ,isnull(b.[Winlost],0)-isnull(b.[Actual_Stake],0) as Amount
      ,b.Status
      ,b.Description
      ,b.Creator
      ,ai.currency
      ,b.[IbcExRate_Mem]
      ,201 as TransType
      ,ac.RefID
      ,b.[IbcExRate_Aff] 
  FROM [Affiliate_12BET].[dbo].[AffCommission] ac with (nolock)
      inner join DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock) on b.TransID=ac.RelNo
      left join AffInfo ai with (nolock) on ai.AffID=b.custid
GO
set identity_insert AffTrans off

update AffCommission with (rowlock,updLock)
set RelNo=RefID
where SportID=1



Select * from AffCommission with (nolock)
Select * from AffTrans  with (nolock) where TransType=201
Select * from CommGroup with (nolock)
Select * from GroupSetting with (nolock)

USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if (not exists (select 1 from AffTrans with (nolock)) )
begin
	truncate table AffTrans
end

if exists (select 1 from AffTrans with (nolock) where TransType=202)
  begin
      Delete AffTrans where TransType=202
  end
 
 
 -- AffTrans
set identity_insert AffTrans on
GO 
 declare @TransType int
  select @TransType=202 
  INSERT INTO AffTrans
           ([TransID]
            ,[AffID]
           ,[TransDate]
           ,[CompletedDate]
           ,[Amount]
          ,[Status]
           ,[Description]
           ,[Creator]
           ,[Currency]
           ,[ActualRate]
           ,[TransType]
           ,[RefID]
           ,[AffExRate])
  SELECT b.[TransID]
      ,b.[CustID]
      ,b.[TransDate]
      ,b.[CompletedDate]
      ,isnull([Winlost],0)-isnull([Actual_Stake],0) as Amount
     ,(case when b.[Status]='Running' then 'pending' else b.[Status] end) as Status      
      ,b.[Description]
      ,b.[Creator]
      ,ai.currency
      ,b.[IbcExRate_Mem]
      ,@TransType
      ,b.RefNo
      ,b.[IbcExRate_Aff]   
  FROM DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock)
       left join AffInfo ai with (nolock) on ai.AffID=b.custid
  where b.bettype=108          
GO
set identity_insert AffTrans off
GO     

if exists (select 1 from AffPayout with (nolock))
  begin
      truncate table AffPayout
  end
 
 -- AffPayout
set identity_insert AffPayout on
GO 
  INSERT INTO [Affiliate_12BET].[dbo].[AffPayout]
           ([RefID]
            ,[AffID]
           ,[IBCCustID]
           ,[UserName]
           ,[IBCUserName]
           ,[Amount]
           ,[AffPayout]
           ,[AffCurrency]
           ,[MemberExRate]
           ,[AffExRate]
           ,[MemberCurrency]
           ,[TransDate]
           ,[CompletedDate]
           ,[Status]
           ,[AdminDesc]
           ,[AffDesc])
  SELECT b.RefNo
      ,b.[CustID]
      ,b.ToCustID
      ,ai.username
      ,mi.IBCUserName
      ,isnull([Winlost],0)-isnull([Actual_Stake],0) as Amount
      ,(isnull([Winlost],0)-isnull([Actual_Stake],0)) * isnull([IbcExRate_Aff],0) /isnull([IbcExRate_Mem],1) as AffPayout
      ,ai.currency
      ,[IbcExRate_Mem]
      ,[IbcExRate_Aff]
      ,mi.currency
      ,[TransDate]
      ,[CompletedDate]      
      ,(case when b.[Status]='Running' then 'pending' else b.[Status] end) as Status      
      ,[Description]
      ,'' as AffDesc      
  FROM DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock)
       left join MemberInfo mi with (nolock) on mi.IbCCustID=b.ToCustID
       left join AffInfo ai with (nolock) on ai.AffID=b.custid
       
  where b.bettype=108 and b.RefNo<>0 and b.RefNo is not null   

   --    Some transaction that have RefNo = 0    
 --- Insert without Refno, but must update back to AffTrans for these transactions
Declare @Temp table([No] [int] IDENTITY(1,1),
    [TransID] bigint,
	[AffID] [int],
	[IBCCustID] [int],
	[UserName] [varchar](30),
	[IBCUserName] [varchar](30),
	[Amount] [money],
	[AffPayout] [money],
	[AffCurrency] [int],
	[MemberExRate] [float],
	[AffExRate] [float],
	[MemberCurrency] [int],
	[TransDate] [datetime],
	[CompletedDate] [datetime],
	[Status] [nvarchar](50),
	[AdminDesc] [nvarchar](300),
	[AffDesc] [nvarchar](300))

declare @MaxRefNo bigint
Select @MaxRefNo=max(RefID) from AffPayout with (nolock)
Select @MaxRefNo=isnull(@MaxRefNo,0)

INSERT INTO @Temp
           ([TransID]
            ,[AffID]
           ,[IBCCustID]
           ,[UserName]
           ,[IBCUserName]
           ,[Amount]
           ,[AffPayout]
           ,[AffCurrency]
           ,[MemberExRate]
           ,[AffExRate]
           ,[MemberCurrency]
           ,[TransDate]
           ,[CompletedDate]
           ,[Status]
           ,[AdminDesc]
           ,[AffDesc])
  SELECT
        b.TransID  
       ,b.[CustID]
      ,b.ToCustID
      ,ai.username
      ,mi.IBCUserName
      ,isnull([Winlost],0)-isnull([Actual_Stake],0) as Amount
      ,(isnull([Winlost],0)-isnull([Actual_Stake],0)) * isnull([IbcExRate_Aff],0) /isnull([IbcExRate_Mem],1) as AffPayout
      ,ai.currency
      ,[IbcExRate_Mem]
      ,[IbcExRate_Aff]
      ,mi.currency
      ,[TransDate]
      ,[CompletedDate]      
      ,(case when b.[Status]='Running' then 'pending' else b.[Status] end) as Status   
      ,[Description]
      ,'' as AffDesc      
  FROM DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock)
       left join MemberInfo mi with (nolock) on mi.IbCCustID=b.ToCustID
       left join AffInfo ai with (nolock) on ai.AffID=b.custid       
  where b.bettype=108 and (b.RefNo=0 or b.RefNo is null)    
  
 INSERT INTO [Affiliate_12BET].[dbo].[AffPayout]
           ([RefID]
            ,[AffID]
           ,[IBCCustID]
           ,[UserName]
           ,[IBCUserName]
           ,[Amount]
           ,[AffPayout]
           ,[AffCurrency]
           ,[MemberExRate]
           ,[AffExRate]
           ,[MemberCurrency]
           ,[TransDate]
           ,[CompletedDate]
           ,[Status]
           ,[AdminDesc]
           ,[AffDesc])
  Select   @MaxRefNo + [No] as RefID
           ,[AffID]
           ,[IBCCustID]
           ,[UserName]
           ,[IBCUserName]
           ,[Amount]
           ,[AffPayout]
           ,[AffCurrency]
           ,[MemberExRate]
           ,[AffExRate]
           ,[MemberCurrency]
           ,[TransDate]
           ,[CompletedDate]
           ,[Status]
           ,[AdminDesc]
           ,[AffDesc]
  from @Temp

  update d 
  set RefID=@MaxRefNo + [No]
  from AffTrans d with (rowlock,updlock)
      inner join @Temp t on t.TransID=d.TransID
  
GO
set identity_insert AffPayout off

GO   

  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from TrackingCode with (nolock))
  begin
      truncate table TrackingCode
  end
  

-- Tracking Code
SET IDENTITY_INSERT TrackingCode ON
GO
INSERT INTO TrackingCode (
	TrackingID,
	AffID,
	TrackingCode,
	CreatedDate,
	IP
)
SELECT 
	TrackingID,
	AffiliateID,
	TrackingCode,
	CreateDate,
	IP
from DB03.[12BetAffiliate].dbo.Affiliate_TrackingCode with (nolock)	
GO
SET IDENTITY_INSERT TrackingCode OFF
GO	
  
  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from ClickStatistics with (nolock))
  begin
      truncate table ClickStatistics
  end
  

-- ClickStatistics
INSERT INTO ClickStatistics (
	TrackingID,
	UpdatedTime,
	IP,
	Date,
	Browser,
	URLReferrer
)
SELECT 
	TrackingID,
	UpdateTime,
	IP,
	Date,
	Browser,
	URLReferrer
from DB03.[12BetAffiliate].dbo.Affiliate_ClickStatistics	
GO         

  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from ClickStatisticsSum with (nolock))
  begin
      truncate table ClickStatisticsSum
  end
  
-- ClickStatisticsSum
INSERT INTO ClickStatisticsSum (
	AffId,
	TrackingID,
	Date,
	IsForMonth,
	TotalClick,
	UniqueClick
)
SELECT 
	AffiliateID,
	TrackingID,
	Date,
	IsForMonth,
	TotalClick,
	UniqueClick
from DB03.[12BetAffiliate].dbo.Affiliate_ClickStatisticsSum	with (nolock) 
GO

  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from ClickStatistics_bk with (nolock))
  begin
      truncate table ClickStatistics_bk
  end
  
-- ClickStatistics_bk
INSERT INTO ClickStatistics_bk (
	TrackingID,
	UpdatedTime,
	IP,
	Date,
	Browser,
	URLReferrer
)
SELECT 
	TrackingID,
	UpdateTime,
	IP,
	Date,
	Browser,
	URLReferrer
from DB03.[12BetAffiliate].dbo.Affiliate_ClickStatistics_bk with (nolock)	
GO


         


 


