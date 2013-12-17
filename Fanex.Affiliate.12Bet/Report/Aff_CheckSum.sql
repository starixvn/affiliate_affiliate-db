ALTER PROCEDURE [dbo].[Aff_CheckSum]
	@IsMatch bit = 1 output,
	@Date smalldatetime = null
AS
/*
Created: @VinhTrinh
Task :
	- Check the summary of winlost + bonus + turnover + deposit + withdrawal + Adjustment + outstanding of MemberDaily table with bettrans
	- Check on the 9th day of every month to make sure the job is run exactly.
DB: DB052.Affiliate_12BET
Original: [Aff_CheckSum]
Revisions:    
		 - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		 - 20120606@Peter : Exclude waiting tickets
		 - 20120717@Johnny : Exclude Horse racing data and run for yesterday only
		 - 20120718@Johnny : Add parameter @Date to Check
		 - 20130306@Johnny: Sportbook bettype is less than 999 and exclude bettype from 31 to 120
*/

Set Nocount On

--Bettrans variables
Declare @BT_Deposit money, @BT_Withdrawal money, @BT_Bonus money, @BT_Adjustment money, @BT_Turnover money, @BT_Winlost money
--MemberDaily variables
Declare @MD_Deposit money, @MD_Withdrawal money, @MD_Bonus money, @MD_Adjustment money, @MD_Turnover money, @MD_Winlost money
Declare @MoveBetsDay smalldatetime

--Check sum data for the day before yesterday
Declare @PreviousDate smalldatetime, @SportbookId int
select @PreviousDate = isnull(@Date, dateadd(d, 0, datediff(d, 0, current_timestamp) - 2))
select @SportbookId = dbo.Aff_GetSportID('SportsBook')
SELECT @MoveBetsDay = max(eventdate) FROM bodb02.dbo.match14 WITH(NOLOCK)   

select 
		@BT_Deposit = isnull(sum(case bettype when 22001 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0),				
		@BT_Withdrawal = -isnull(sum(case when bettype in (22002,22003) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0),
		@BT_Bonus = isnull(sum(case bettype when 22004 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0),
		@BT_Adjustment = isnull(sum(case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0),
		@BT_Turnover = isnull(sum(case when bettype < 999 then isnull(abs(stake),0) else 0 end),0),		
		@BT_Winlost = isnull(sum(case when bettype < 999 and ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0)
from bodb02.dbo.bettrans b with (nolock)		
	INNER JOIN 			
	  (
		select IBCCustID
		from MemberInfo m with(nolock)
		where CreatedDate is not null
			and IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@PreviousDate)>=0 )
			and datediff(d,CreatedDate,@PreviousDate)>=0
	  
	  ) m on m.IBCCustID=b.custid
where winlostdate = @PreviousDate
	 and (bettype < 999 or bettype in (22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005))
	 and bettype not between 31 and 120 --Not include Casino and Number Game
	 --and bettype not in (31,32,33,41,42,43)   
	 and StatusID not in (101, 102, 103, 121,1)
	 and b.custid > 0

if(@PreviousDate <= @MoveBetsDay)
Begin--Select Turnover and winlost again in the date that equal or less than Move bet date
	Select @BT_Turnover = sum(isnull(abs(stake),0)),		
		@BT_Winlost = isnull(sum(case when ruben=1 then isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0) else 0 end),0)					
	from bodb02.dbo.bettrans14 b with (nolock)		
			INNER JOIN 			
			  (
				select IBCCustID,AffID
				from MemberInfo m with(nolock)
				where  CreatedDate is not null	 
					  and datediff(d,CreatedDate,@PreviousDate)>=0
					  and   IBCCustID not in (select IBCCustID from MemberRemoval with (nolock) where datediff(mm,RemovedDate,@PreviousDate)>=0 )			  
			  ) m on m.IBCCustID=b.custid
	where winlostdate = @PreviousDate
			and bettype<999
			and bettype not between 31 and 120 --Not include Casino and Number Game
			and StatusID not in (101, 102, 103, 121, 1)
			--and bettype not in (31,32,33,41,42,43)   
		and b.custid > 0
End
		
select 
		@MD_Deposit = isnull(sum(isnull(Deposit, 0)), 0),
		@MD_Withdrawal = isnull(sum(isnull(Withdrawal, 0)), 0),
		@MD_Bonus = isnull(sum(isnull(Bonus, 0)), 0),
		@MD_Adjustment = isnull(sum(isnull(Adjustment, 0)), 0),
		@MD_Turnover = isnull(sum(isnull(Turnover, 0)), 0),
		@MD_Winlost = isnull(sum(isnull(Winlost, 0)), 0)
from MemberDaily nolock
where WinlostDate = @PreviousDate
	and sporttype = @SportbookId


if(@MD_Deposit <> @BT_Deposit or @MD_Withdrawal <> @BT_Withdrawal or @MD_Bonus <> @BT_Bonus or @MD_Adjustment <> @BT_Adjustment or @MD_Turnover <> @BT_Turnover or @MD_Winlost <> @BT_Winlost)
Begin
	Select @IsMatch = 0
	
	select 'Summary Data in Bettrans' as Description
			, @BT_Deposit as Deposit
			, @BT_Withdrawal as Withdrawal
			, @BT_Bonus as Bonus
			, @BT_Adjustment as Adjustment
			, @BT_Turnover as Turnover
			, @BT_Winlost as Winlost
	Union All
	select 'Summary Data in MemberDaily' as Description
			, @MD_Deposit
			, @MD_Withdrawal 
			, @MD_Bonus
			, @MD_Adjustment 
			, @MD_Turnover
			, @MD_Winlost
	return
end

Select @IsMatch = 1 

GO
GRANT EXECUTE ON [dbo].[Aff_CheckSum] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckSum] TO [VNTeam] 
GO