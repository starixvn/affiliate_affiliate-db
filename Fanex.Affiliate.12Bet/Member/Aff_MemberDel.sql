USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberDel]    Script Date: 04/13/2010 04:57:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  ALTER PROCEDURE [dbo].[Aff_MemberDel]
	@IBCCustID int,
	@UserID int,	
	@IP varchar(20),	
	@AffID int=null OUTPUT,
	@RefNo bigint=0 OUTPUT,
	@DepositCustID int=0 OUTPUT,    
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
begin
/*
Created: 20090910@Peter
Task : Remove a member  from Affiliate
DB: DB052.Affiliate_12BET
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
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
--Check IBCCustID

select @AffId=AffId,@DepositCustID=DepositCustID from MemberInfo(nolock) where IBCCustID=@IBCCustID and IsRemoved = 0
if(@AffID is null)
begin
	SELECT @ErrMsg ='This member does not exist or be removed before!', @ErrCode = 1001
	RETURN
end
/*exec [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
	@IBCCustID =@IBCCustID,	
	@NewAffId =0,	
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg =@ErrMsg OUTPUT
	
if(@ErrCode<>0)
   return*/

DECLARE @LogData nvarchar(4000),@SPName varchar(100), @FirstDayOfTheMonth smalldatetime
SELECT @LogData = 'Remove member. IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
		, @FirstDayOfTheMonth = dateadd(m, datediff(m, 0, Current_Timestamp), 0)  
begin transaction
 begin try
   --Write the log 
	/*select @SPName='Aff_MemberUpdAffID'
	EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@AffID,
		@Typename= 'Member',	
		@SPName=@SPName ,
		@RefNo=@RefNo OUTPUT,
		@IP =@IP,
		@Details=@LogData	*/

  update MemberInfo with (rowlock,updlock)
  set IsRemoved = 1
  where IBCCustID=@IBCCustID

  Insert Into MemberDailyRemoved
  ([WinlostDate]
		   ,[IBCCustID]
		   ,[SportType]
		   ,[Currency]
		   ,[Deposit]
		   ,[Withdrawal]
		   ,[Bonus]
		   ,[Adjustment]
		   ,[Turnover]
		   ,[Outstanding]
		   ,[Winlost]
		   ,[AWinlost]
		   ,[ABonus]
		   ,[AffExRate]
		   ,[MemberExRate]
		   ,[DrawGame]
		   ,[PSP]
		   ,[Marketing]
		   ,[AffID]
		   ,[MemWinlostFake]
		   ,[MemOddsFee])
		   
  select [WinlostDate]
		   ,[IBCCustID]
		   ,[SportType]
		   ,[Currency]
		   ,[Deposit]
		   ,[Withdrawal]
		   ,[Bonus]
		   ,[Adjustment]
		   ,[Turnover]
		   ,[Outstanding]
		   ,[Winlost]
		   ,[AWinlost]
		   ,[ABonus]
		   ,[AffExRate]
		   ,[MemberExRate]
		   ,[DrawGame]
		   ,[PSP]
		   ,[Marketing]
		   ,[AffID]
		   ,[MemWinlostFake]
		   ,[MemOddsFee]
  from MemberDaily with (nolock)
  where IBCCustID=@IBCCustID and datediff(m,winlostdate,current_timestamp)=0 and SportType>0
  
  Delete MemberDaily
  where IBCCustID=@IBCCustID and datediff(m,winlostdate,current_timestamp)=0 and SportType>0
  
--Update AFFDaily here
DELETE FROM AffDaily 
WHERE AffId = @AffId
	and datediff(m,winlostdate,current_timestamp)=0

Insert into AffDaily
  ([AffID]
		   ,[Currency]
		   ,[Winlostdate]
		   ,[SportID]
		   ,[ExRate2]
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
		   ,[MemOddsFee])

select d.AffID as AffID,      
	d.Currency as Currency,       
	d.Winlostdate as Winlostdate,       
	d.SportType as SportID,      
	d.AffExRate as Exrate2,       
	SUM(isnull(d.Deposit, 0)) as MemDeposit,   
	SUM(isnull(d.Withdrawal,0)) as MemWithdrawal,       
	SUM(isnull(d.Turnover, 0)) as MemTurnover,       
	SUM(isnull(d.Bonus, 0)) as MemBonus,    
	SUM(isnull(d.Adjustment,0)) as MemAdjustment,    
	0 as MemMarketing,    
	SUM(isnull(d.PSP,0)) as MemPSP,        
	SUM(isnull(d.Winlost, 0)) as MemWinLost,        
	0 as AffWinLost,      
	-SUM(d.Winlost) as HouseWinLost,        
	0 as AffNetWinlost,      
	0 as HouseNetWinLost,
	0 as MemWinlostFake,		
	0 as MemOddsFee     
from MemberDaily d with (nolock)    
where AffId = @AffId
	and d.WinlostDate >= @FirstDayOfTheMonth
GROUP BY d.AffID,d.Winlostdate, d.Currency, d.SportType,d.AffExRate  

update AffDaily with (rowlock,updlock)

set [MemMarketing]= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0),
	MemOddsFee= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0),  
	HouseNetWinLost=HouseWinLost
					- isnull(MemBonus,0)  * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Bonus',Winlostdate),0)   
					-isnull(MemAdjustment,0)
					-isnull(MemPSP,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',Winlostdate),0)
					- abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)
					- abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0),
	MemWinlostFake=-(-isnull(MemWinlost,0)
					 -isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',Winlostdate),0)		
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)		
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0)
					)
where AffId = @AffId
   and WinlostDate >= @FirstDayOfTheMonth
	  
DELETE FROM AffDailySummary 
WHERE AffId = @AffId
	and WinlostDate >= @FirstDayOfTheMonth    

INSERT INTO [dbo].[AffDailySummary]
		   ([AffID]
		   ,[Winlostdate]
		   ,[SportID]
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
		   ,[MemWinlostFake])

select      [AffID]
		   ,[Winlostdate]
		   ,[SportID]
		   ,sum([MemDeposit]* ExRate2) as MemDeposit
		   ,sum([MemWithdrawal]*ExRate2) as MemWithdrawal
		   ,sum([MemTurnover]*ExRate2) as MemTurnover
		   ,sum([MemBonus]*ExRate2) as MemBonus
		   ,sum([MemAdjustment] * ExRate2) as MemAdjustment
		   ,0 as MemMarketing	
		   ,sum([MemPSP] * ExRate2) as MemPSP
		   ,sum([MemWinlost] * ExRate2) as MemWinlost
		   ,sum([AffWinlost] * ExRate2) as AffWinlost
		   ,sum([HouseWinlost] * ExRate2) as HouseWinlost
		   ,sum([AffNetWinlost]*ExRate2) as AffNetWinlost
		   ,sum([HouseNetWinlost]*ExRate2) as HouseNetWinlost
		   ,0 as MemOddsFee
		   ,0 as MemWinlostFake

from AffDaily(nolock)
where AffId = @AffId
	and WinlostDate >= @FirstDayOfTheMonth 
group by AffID,Winlostdate,SportID

update AffDailySummary with (rowlock,updlock)
set MemOddsFee=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate),
	MemMarketing=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate),         
	MemWinlostFake=  -(-MemWinlost
					 - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate)
					 - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate)
					 - MemPSP* dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',WinlostDate)) ,    
   
	 HouseNetWinlost=(
						-MemWinlost
						-MemBonus* dbo.Aff_GetDeductionPercent(AffID,SportID,'Bonus',WinlostDate)
						-MemAdjustment
						-MemPSP* dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate)
					 )
			
	 
  where AffId = @AffId
	and WinlostDate >= @FirstDayOfTheMonth 
  
  Insert Into MemberRemoval(IBCCustID,RemovedDate,RemovedBy)
  values(@IBCCustID,current_timestamp,@UserID)

 end try
 begin catch        
		rollback transaction
		--manually rollback on DB02 
		/*exec [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
			@IBCCustID =@IBCCustID,			
			@NewAffId =@AffID,				
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg =@ErrMsg OUTPUT*/
		SELECT @ErrMsg ='Remove member failed!', @ErrCode = 1002  
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



GO
GRANT EXECUTE ON [dbo].[Aff_MemberDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDel] TO [vnteam]