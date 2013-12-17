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