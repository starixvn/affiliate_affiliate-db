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