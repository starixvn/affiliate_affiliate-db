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

