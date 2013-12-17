ALTER function [dbo].[Aff_GetMemberWinlost] (
@AffID int,@SportID tinyint, @MonthDate smalldatetime)
RETURNS money
AS
/*
	Task : Get MemberWinlost for Affiliate
	Author : Peter@20100508
	@MonthDate=null : current month
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120606@Peter : Exclude waiting tickets
	*/
BEGIN	 
	declare @MemberWinlost money
	select @MemberWinlost=0
	
	If Datediff(m, @monthdate, current_timestamp) = 0
	BEGIN
			Declare @Today smalldatetime,@FirstDay smalldatetime,@LastDay smalldatetime,@SportsBookID int,@HorseRacingID int,@MemberWinlostCurrentDate money

			select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')

			Select @FirstDay = cast(cast(year(getdate()) as varchar(5)) + '-' + cast(Month(getdate()) as varchar(5)) + '-' +'1' as smalldatetime)
			--Get last day of inputted month
			Select @Today = convert (varchar(12),current_timestamp)
			select @LastDay=dateadd(d,-1,@Today)  
			
			select @MemberWinlost=sum(isnull(MemWinlost,0) * isnull(ExRate2,0))
			from AffDaily (nolock) 
			where AffId=@AffID and SportId=@SportID and winlostdate between @FirstDay and @LastDay
			
			Select @MemberWinlostCurrentDate=sum(isnull(MemberWinlost,0) * isnull(ExRate2,0))
			from
			(
			select 
						ci.IBCCustID, 
						case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end as SportID,						
						sum(isnull(winlost,0)-isnull(abs(actual_stake),0)+ isnull(playercomm,0)) as MemberWinlost, 					
						e.Actualrate2 as ExRate2
					from MemberInfo ci with (nolock)
						inner join bodb02.dbo.bettrans b with (nolock) on b.custid = ci.IBCCustID
						INNER JOIN Exchange_Current e with (nolock) on e.exchangeid=ci.currency  
					where b.winlostdate=@Today
						and b.ruben=1 
						and ci.AffID=@AffID
						and ci.IsRemoved = 0
						AND Bettype < 19000
						 and bettype not between 71 and 120 --Not include Casino and Number Game
						and StatusID not in (101, 102, 103, 121,1) 
					Group by ci.IBCCustID, case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end,e.Actualrate2
					
				) as a
			where SportID=@SportID	
			
			select @MemberWinlost=isnull(@MemberWinlost ,0) +  isnull(@MemberWinlostCurrentDate,0)
		
		
			
	END
	ELSE
	BEGIN
		Declare @MaxTransDate smalldatetime	
		select @MaxTransDate = Max(winlostdate) From AffCommission(nolock)
		If @MaxTransDate < @monthdate
			BEGIN
				select @MemberWinlost=sum(isnull(MemWinlost,0) * isnull(ExRate2,0))
				from AffDaily (nolock) 
				where AffId=@AffID and SportId=@SportID and datediff(m,WinlostDate,@MonthDate) = 0
			END
		ELSE
			BEGIN
				Select @MemberWinlost = isnull(MemberWinlost, 0) From AffCommission nolock where AffId = @AffId and WinlostDate = @monthdate and SportID=@SportID
			END
	END    
		 
	return  isnull(@MemberWinlost,0)
END


