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

update Afftrans with (rowlock,updlock)
set TransType=204
where transtype=203 and Description = 'Marketing Fee'

GO     