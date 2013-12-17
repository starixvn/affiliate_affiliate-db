 ALTER Procedure [Aff_CurrencyGroupUpdForDailyData]	
	@CommGroupId int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT	
AS
/*
Created: 20110623@DungTong
Task : update currency group for all daily data when we change the setting for commission group that related to currency group
DB: DB052.Affiliate_12Bet
Original:

Revisions:
Parameters:
	 .@ErrCode:  
				  0 : no error raised
				  >0 : there was an error
	 .@ErrMsg :   
				  empty: no error raised
				  others : the error message detail                          
						  
*/
SET NOCOUNT ON

Begin try
--MemberDaily
update MemberDaily with (rowlock,updlock)
Set CurrencyGroup=dbo.[Aff_GetCurrencyGroup] (AffID,SportType,Currency,null)
where datediff (m,winlostdate,current_timestamp)=0 and AffID in
 (
	Select AffID
	from AffInfo (nolock) 
	where GroupID=@CommGroupId
 )
--MemberDailyRemoved
update MemberDailyRemoved with (rowlock,updlock)
Set CurrencyGroup=dbo.[Aff_GetCurrencyGroup] (AffID,SportType,Currency,null)
where datediff (m,winlostdate,current_timestamp)=0 and AffID in
 (
	Select AffID
	from AffInfo (nolock) 
	where GroupID=@CommGroupId
 )
 
--AffDaily
update AffDaily with (rowlock,updlock)
Set CurrencyGroup=dbo.[Aff_GetCurrencyGroup] (AffID,SportID,Currency,null)
where datediff (m,winlostdate,current_timestamp)=0 and AffID in
 (
	Select AffID
	from AffInfo (nolock) 
	where GroupID=@CommGroupId
 )
 
--Recalculate AffDaily Summary
DELETE FROM AffDailySummary 
where datediff (m,winlostdate,current_timestamp)=0 and AffID in
 (
	Select AffID
	from AffInfo (nolock) 
	where GroupID=@CommGroupId
 )

INSERT INTO [dbo].[AffDailySummary]
		   ([AffID]
		   ,[Winlostdate]
		   ,[SportID]
		   ,[CurrencyGroup]
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
		   ,[CurrencyGroup]
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
where datediff (m,winlostdate,current_timestamp)=0 and AffID in
 (
	Select AffID
	from AffInfo (nolock) 
	where GroupID=@CommGroupId
 )
 
group by AffID,Winlostdate,SportID,CurrencyGroup

update AffDailySummary with (rowlock,updlock)
set MemOddsFee=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate),
	MemMarketing=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate),         
	MemWinlostFake=  -(-MemWinlost
					 - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate)
					 - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate)
					 - MemPSP * dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',WinlostDate)) ,    
   
	 HouseNetWinlost=(
						-MemWinlost
						-MemBonus * dbo.Aff_GetDeductionPercent(AffID,SportID,'Bonus',WinlostDate)
						-MemAdjustment
						-MemPSP * dbo.Aff_GetDeductionPercent(AffID,SportID,'PSP',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',WinlostDate)
					 )
			
	 
 where datediff (m,winlostdate,current_timestamp)=0 and AffID in
 (
	Select AffID
	from AffInfo (nolock) 
	where GroupID=@CommGroupId
 )
 
  
end try
begin catch
 Select @ErrMsg=ERROR_MESSAGE(),@ErrCode=51111
end catch
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyGroupUpdForDailyData] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CurrencyGroupUpdForDailyData] TO [vnteam]
