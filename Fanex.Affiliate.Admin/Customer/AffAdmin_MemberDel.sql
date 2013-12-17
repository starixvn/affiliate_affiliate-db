-- =============================================
-- Script Template
-- =============================================
ALTER PROCEDURE [dbo].[AffAdmin_MemberDel]  
	@Username varchar(30),  
	@UserID int,   
	@IP varchar(20),    
	@RefNo bigint=0 OUTPUT,   
	@ErrCode int = 0 OUTPUT  
AS  
begin  
/*  
Created: 20090910@Peter  
Task : Remove a member  from Affiliate  
DB: DB052.Affiliate_ZZun  
Original:   
  
Revisions:  
          Peter@20100413 : Remove the calling to sp [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]  
                           coz AffiliateID in custinfo will be removed.    
          Johnny@20100512: Re-calculate AffDaily if member is removed.  
          Peter@20100927 : Add OddsFee column for AffDetail  
  
Param's Explanation:  
.@IP: ip of computer sent,  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert unsuccessful.  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
--Check permission-----------------------------  
  
EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output 
   
If @ErrCode <> 0  
 RETURN  
-----------------------------------------------  
--Check IBCCustID  
DECLARE @AffID int

select @AffId=AffId from MemberInfo(nolock) where UserName=@UserName and IsRemoved = 0  
if(@AffID is null)  
begin  
 SELECT @ErrCode = 4
 RETURN  
end  
  
DECLARE @LogData nvarchar(4000),@SPName varchar(100), @FirstDayOfTheMonth datetime  
SELECT @LogData = 'Remove member. UserName=' + dbo.Aff_ToString(@UserName)  
  , @FirstDayOfTheMonth = dbo.Aff_GetFirstDayOfMonth(Current_Timestamp)   
begin transaction  
 begin try  
     
  update MemberInfo with (rowlock,updlock)
  set IsRemoved = 1
  where UserName=@UserName

  INSERT INTO [MemberDailyRemoved]
      ([UserName]
      ,[WinlostDate]
      ,[ProductID]
      ,[AffID]
      ,[IBCCustID]
      ,[Currency]
      ,[AffCurrency]
      ,[AffExRate]
      ,[SysCurrency]
      ,[SysExRate]
      ,[Deposit]
      ,[Withdrawal]
      ,[Bonus]
      ,[Adjustment]
      ,[Turnover]
      ,[Outstanding]
      ,[Winlost]
      ,[DrawGame]
      ,[PSP]
      ,[Marketing]
      ,[MemWinlostFake]
      ,[MemOddsFee]
      ,[MemPLayTechFee]
      ,[AffTransfer]
      ,[Transfer3rd]
      ,[BetCount]
      ,[PlayerComm]
      ,[TurnoverNoDraw]
      ,[BetCountNoDraw]
      ,[TurnoverDraw])
           
  select [UserName]
      ,[WinlostDate]
      ,[ProductID]
      ,[AffID]
      ,[IBCCustID]
      ,[Currency]
      ,[AffCurrency]
      ,[AffExRate]
      ,[SysCurrency]
      ,[SysExRate]
      ,[Deposit]
      ,[Withdrawal]
      ,[Bonus]
      ,[Adjustment]
      ,[Turnover]
      ,[Outstanding]
      ,[Winlost]
      ,[DrawGame]
      ,[PSP]
      ,[Marketing]
      ,[MemWinlostFake]
      ,[MemOddsFee]
      ,[MemPLayTechFee]
      ,[AffTransfer]
      ,[Transfer3rd]
      ,[BetCount]
      ,[PlayerComm]
      ,[TurnoverNoDraw]
      ,[BetCountNoDraw]
      ,[TurnoverDraw]
  from MemberDaily with (nolock)
  where UserName=@UserName and datediff(m,winlostdate,current_timestamp)=0 
  
  Delete MemberDaily
  where UserName=@UserName and datediff(m,winlostdate,current_timestamp)=0
  
--Update AFFDaily here
DELETE FROM AffDaily 
WHERE AffId = @AffId
	and datediff(m,winlostdate,current_timestamp)=0

INSERT INTO AffDaily
        ([AffID]
        ,[MemCurrency]
        ,[Winlostdate]
        ,[ProductID]
        ,[AffCurrency]
        ,[AffExRate]
        ,[SysCurrency]
        ,[SysExRate]
		,[MemDeposit]
		,[MemWithdrawal]
        ,[MemTurnover]
		,[MemBonus]
		,[MemAdjustment]
        ,[MemMarketing]
        ,[MemPSP]
        ,[MemWinlost]
        ,[AffWinlost]
        ,[HouseWinlost]
        ,[AffNetWinlost]
        ,[HouseNetWinlost]
        ,[MemWinlostFake]
        ,[MemOddsFee]
		,[MemPLayTechFee]
		,[MemAffTransfer]
        ,[MemTransfer3rd]
        ,[MemBetCount]
        ,[MemPlayerComm]
        ,[ActivePlayer]
        ,[MemTurnoverNoDraw]
        ,[MemBetCountNoDraw]
        ,[MemTurnoverDraw])

select m.[AffID]
		,m.[Currency] as [MemCurrency]
        ,m.[WinlostDate]
        ,m.[ProductID]
        ,m.[AffCurrency]
        ,m.[AffExRate]
        ,m.[SysCurrency]
        ,m.[SysExRate]
		,Sum(Deposit) as MemDeposit
		,Sum(Withdrawal) as MemWithdrawal
        ,Sum(Turnover) as MemTurnover
		,Sum(Bonus) as MemBonus
		,Sum(Adjustment) as MemAdjustment
		,Sum(Marketing) as MemMarketing	
		,Sum(PSP) as MemPSP
        ,Sum(Winlost) as MemWinlost
        ,0 as AffWinlost
        ,-Sum(Winlost)  as HouseWinlost
        ,0 as AffNetWinlost
        ,0 as HouseNetWinlost
        ,Sum(MemWinlostFake) as MemWinlostFake
        ,Sum(MemOddsFee) as MemOddsFee          		   
		,Sum(MemPLayTechFee) as MemPLayTechFee
		,Sum([AffTransfer])
        ,Sum([Transfer3rd])
        ,Sum([BetCount])
        ,Sum([PlayerComm])
        ,Sum(case when turnover>0 then 1 else 0 end) as [ActivePlayer]
        ,Sum([TurnoverNoDraw])
        ,Sum([BetCountNoDraw])
        ,Sum([TurnoverDraw])

from MemberDaily(nolock) as m
where m.WinlostDate >= @FirstDayOfTheMonth
     and m.AffID=@AffId
group by m.AffID
	,m.Winlostdate
	,m.ProductID
	,m.Currency
    ,m.[AffCurrency]
    ,m.[AffExRate]
    ,m.[SysCurrency]
    ,m.[SysExRate]

update AffDaily with (rowlock,updlock)    
set 
	HouseNetWinLost=HouseWinLost  
		 - isnull(MemBonus,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',Winlostdate),0)     
		 -isnull(MemAdjustment,0)  
		 -isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',Winlostdate),0)  
		 - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',Winlostdate),0)  
		 - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',Winlostdate),0)
		 - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',Winlostdate),0)  
where AffId = @AffId
   and WinlostDate >= @FirstDayOfTheMonth
      
DELETE AffDailySummary 
WHERE AffId = @AffId
	and WinlostDate >= @FirstDayOfTheMonth    

--Update [AffDailySummary] table
INSERT INTO [dbo].[AffDailySummary]  
	([AffID]  
	,[Winlostdate]  
	,[ProductID]
	,[AffCurrency]
	,[SysCurrency]   
	,[MemDeposit]  
	,[MemWithdrawal]  
	,[MemTurnover]  
	,[MemBonus]  
	,[MemAdjustment]  
	,[MemMarketing]  
	,[MemPSP]  
	,[MemWinlost]  
	,[AffWinlost]  
	,[HouseWinlost]  
	,[AffNetWinlost]  
	,[HouseNetWinlost]  
	,[MemOddsFee]  
	,[MemPLayTechFee]
	,[MemWinlostFake]
	,[MemDeposit_aff]
	,[MemWithdrawal_aff]
	,[MemTurnover_aff]
	,[MemBonus_aff]
	,[MemAdjustment_aff]
	,[MemMarketing_aff]
	,[MemPSP_aff]
	,[MemWinlost_aff]
	,[AffWinlost_aff]
	,[HouseWinlost_aff]
	,[AffNetWinlost_aff]
	,[HouseNetWinlost_aff]
	,[MemOddsFee_aff]
	,[MemWinlostFake_aff]
	,[MemPLayTechFee_aff]
	,[MemAffTransfer]
    ,[MemTransfer3rd]
    ,[MemBetCount]
    ,[MemPlayerComm]
    ,[MemAffTransfer_aff]
    ,[MemTransfer3rd_aff]
    ,[MemPlayerComm_aff]
    ,[MemTurnoverNoDraw]
    ,[MemBetCountNoDraw]
    ,[MemTurnoverNoDraw_aff]
    ,[MemTurnoverDraw]
    ,[MemTurnoverDraw_aff]

     )  
  
select [AffID]  
	,[Winlostdate]  
	,[ProductID]
	,[AffCurrency]
	,[SysCurrency]  
	,Sum([MemDeposit] * SysExRate) as [MemWithdrawal]
	,Sum([MemWithdrawal] * SysExRate) as [MemWithdrawal]
	,Sum([MemTurnover] * SysExRate) as [MemTurnover]
	,Sum([MemBonus] * SysExRate) as   [MemBonus]
	,Sum([MemAdjustment] * SysExRate) as   [MemAdjustment]
	,Sum([MemMarketing] * SysExRate) as  [MemMarketing] 
	,Sum([MemPSP] * SysExRate) as   [MemPSP]
	,Sum([MemWinlost] * SysExRate) as   [MemWinlost]
	,Sum([AffWinlost] * SysExRate) as [AffWinlost]  
	,-Sum([MemWinlost] * SysExRate) as  [HouseWinlost] 
	,0 as  [AffNetWinlost] 
	,0 as  [HouseNetWinlost] 
	,Sum([MemOddsFee] * SysExRate) as   [MemOddsFee]
	,Sum([MemPLayTechFee] * SysExRate) as [MemPLayTechFee]
	,0 as [MemWinlostFake]
	,Sum([MemDeposit] * AffExRate) as [MemDeposit_aff]
	,Sum([MemWithdrawal] * AffExRate) as [MemWithdrawal_aff]
	,Sum([MemTurnover] * AffExRate) as [MemTurnover_aff]
	,Sum([MemBonus] * AffExRate) as [MemBonus_aff]
	,Sum([MemAdjustment] * AffExRate) as [MemAdjustment_aff]
	,Sum([MemMarketing] * AffExRate) as [MemMarketing_aff]
	,Sum([MemPSP] * AffExRate) as [MemPSP_aff]
	,Sum([MemWinlost] * AffExRate) as [MemWinlost_aff]
	,0 as [AffWinlost_aff]
	,-Sum([MemWinlost] * AffExRate) as [HouseWinlost_aff]
	,0 as [AffNetWinlost_aff]
	,0 as [HouseNetWinlost_aff]
	,Sum([MemOddsFee] * AffExRate) as [MemOddsFee_aff]
	,Sum([MemWinlostFake] * AffExRate) as [MemWinlostFake_aff]
	,Sum([MemPLayTechFee] * AffExRate) as [MemPLayTechFee_aff]
	,Sum([MemAffTransfer] * SysExRate) 
    ,Sum([MemTransfer3rd] * SysExRate)
    ,Sum([MemBetCount])
    ,Sum([MemPlayerComm]* SysExRate)
    ,Sum([MemAffTransfer] * AffExRate)
    ,Sum([MemTransfer3rd]* AffExRate)
    ,Sum([MemPlayerComm]* AffExRate)
    ,Sum([MemTurnoverNoDraw]* SysExRate)
    ,Sum([MemBetCountNoDraw])
    ,Sum([MemTurnoverNoDraw]* AffExRate)
    ,Sum([MemTurnoverDraw]* SysExRate)
    ,Sum([MemTurnoverDraw]* AffExRate)

from AffDaily(nolock)
where AffId = @AffId
	and WinlostDate >= @FirstDayOfTheMonth 
group by AffID, Winlostdate, ProductID, AffCurrency, SysCurrency

update AffDailySummary with (rowlock,updlock)  
set 
	 /*MemWinlostFake=  -(-MemWinlost  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)
		  - MemPSP * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)) ,      
     */
	  HouseNetWinlost=(  
		  -MemWinlost  
		  -MemBonus * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)  
		  -MemAdjustment  
		  -MemPSP * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)  
		  ) ,
		  
		  HouseNetWinlost_aff=(  
		  -MemWinlost_aff  
		  -MemBonus_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)  
		  -MemAdjustment_aff  
		  -MemPSP_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)  
		  - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
		  - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
		  - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)  
		  )   

     
  where AffId = @AffId
	and WinlostDate >= @FirstDayOfTheMonth 
  -- update TotalMembers for this affiliate

  update AffInfo with (rowlock,updlock)
  set TotalMembers= TotalMembers-1
  where AffID=@AffID

  Insert Into MemberRemoval(UserName,RemovedDate,RemovedBy)
  values(@UserName,current_timestamp,@UserID)
  
 end try  
 begin catch          
  rollback transaction    
        SELECT @ErrCode = 5
        return  
 end catch   
COMMIT TRANSACTION   
  
--Write the log   
  
select @SPName=OBJECT_NAME(@@ProcID)  
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserID,   
 @AffID=@AffID,  
 @Typename= 'Member',   
 @SPName=@SPName ,  
 @RefNo=@RefNo,  
 @IP =@IP,  
 @Details=@LogData   
  
end   
  