ALTER PROCEDURE [dbo].[Aff_PlayersSelDetail]
	@AffID int,
	@sporttype tinyint = 0,
	@MonthDate smalldatetime = null,
	@PageSize int=200,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
	Created: @VietHoang
	Task : 
	DB: DB052.Affiliate_12BET	
	Revisions:		
		- 20100511@Johnny: upgrade performance(paging first and then calculate member related)
		- 20101228@Henry: change bettype to new range
		- 20120606@Peter : Exclude waiting tickets
	Param's Explanation:
		• @AffID : Affiliate custid
		• @MonthDate: Month search. If Month is null => get all month Else get just the specification month		
		----Continue....
*/
SET NOCOUNT ON
DECLARE @Today smalldatetime, @fdate smalldatetime, @tdate smalldatetime
SELECT @Today = convert(varchar(10),current_timestamp,120)

IF @MonthDate is not NULL
BEGIN
	SELECT @fdate = DATEADD(mm, DATEDIFF(m,0,@MonthDate),0)
	select @tdate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@MonthDate)+1, 0))	
END

DECLARE @SportsBookID int,@HorseRacingID int
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')

Declare @TmpCustId as table(IBCCustId int, IBCUserName nvarchar(30), username nvarchar(50), Currency int, RegisteredDate datetime)

insert into @TmpCustId
select distinct tmp.IBCCustId, m.IBCUserName, m.username, m.Currency, m.RegisteredDate
from (
		Select distinct CustId as IBCCustId
		From bodb02.dbo.bettrans b with (nolock) 
			inner join (
					select IBCCustId, IBCUserName, username, Currency 
					from MemberInfo with (nolock) 
					where AffID = @AffID and IsRemoved=0) m  on m.IbcCustID=b.custID
		where (@MonthDate is NULL OR DATEDIFF(m,@tdate,@today) = 0)
			and b.winlostdate = @Today
			AND (Bettype < 99  or bettype in (21001, 21002, 21003, 21004, 21005, 22005,22001,22004,22002,22003))		
			AND bettype not in (71,72,73,74,75,76,77,78,79)
			and StatusID not in (101, 102, 103, 121,1)
			--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')
		Union all
		Select distinct d.IBCCustId as IBCCustId
		From MemberDaily d with (nolock)
		where (case when @MonthDate is NULL then--for searching all month
					case when d.winlostdate < @Today then 1 else 0 end
				else--for searching 1 month only
					case when d.winlostdate between @fdate and @tdate then 1 else 0 end
				end
				) = 1
			and case when @sporttype = 0 then d.sporttype else @sporttype end = d.sporttype
			and d.AffID = @AffID
			and (turnover > 0 or deposit > 0)
	) tmp
	inner join (
		select IBCCustId, IBCUserName, username, Currency, RegisteredDate
		from MemberInfo with (nolock) 
		where AffID = @AffID) m  on m.IbcCustID=tmp.IBCCustId 
--select * from @TmpCustId
--Paging
select @NRows=count(*)
from @TmpCustId
	
if @NRows <=0
  return	
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	

Create table #ListCustId(IBCCustId int Primary Key, IBCUserName nvarchar(30), username nvarchar(50), Currency int, RegisteredDate datetime)

insert into #ListCustId
select IBCCustId, IbcUsername, username, Currency, RegisteredDate
from
	(
	SELECT TOP(@RowEnd) ROW_NUMBER() Over(Order by username) AS TheCount,
		IBCCustId, 
		IbcUsername, 
		username,
		Currency,
		RegisteredDate
	FROM @TmpCustId		
	) x
where x.TheCount between @RowStart and @RowEnd	

--Declare @PlayersDetail as  table(IBCUserName nvarchar(30), username nvarchar(50), turnover money, winlost money, deposit money, bonus money, adjustment money, psp money)

select IBCUserName, Username, RegisteredDate,
		isnull(sum(turnover), 0) as turnover, 
		isnull(sum(winlost), 0) as winlost,
		isnull(sum(deposit ), 0) as deposit,
		isnull(sum(withdrawal), 0) as withdrawal,
		isnull(sum(bonus), 0) as bonus, 
		isnull(sum(Adjustment), 0) as Adjustment,
		isnull(sum(PSP ), 0) as PSP 
From(
	select IBCUserName, m.username, m.RegisteredDate,
		isnull(sum(case 
				when @SportType = 0 and bettype < 99 then 
					(case when Bettype in (33,43) and liveawayscore = 0 then isnull(stake, 0) / 2 * e.Actualrate2 else isnull(stake, 0) * e.Actualrate2 end)
				when @SportType = @SportsBookID and bettype not in (31,32,33,41,42,43) then stake * e.ActualRate2
				when @SportType = @HorseRacingID and bettype in (31,32,33,41,42,43) then 
					(case when Bettype in (33,43) and liveawayscore = 0 then isnull(stake, 0) / 2 * e.Actualrate2 else isnull(stake, 0) * e.Actualrate2 end)
				else 0 end)
			, 0) as turnover, 
		isnull(sum(case 
			when @SportType = 0 and bettype < 99 and ruben=1 then (winlost-actual_stake+playercomm) * e.ActualRate2
			when @SportType = @SportsBookID and ruben=1 and bettype not in (31,32,33,41,42,43) then (winlost-actual_stake+playercomm) * e.ActualRate2
			when @SportType = @HorseRacingID and ruben=1 and bettype in (31,32,33,41,42,43) then (winlost-actual_stake+playercomm) * e.ActualRate2
			else 0 end)
		,0) as WinLost,
		isnull(sum(case when @SportType < 2 and bettype = 22001 then (winlost-actual_stake) * e.ActualRate2 else 0 end),0) as Deposit,
		isnull(sum(case when @SportType < 2 and bettype in (22002,22003) then (winlost-actual_stake) * e.ActualRate2 else 0 end),0) as Withdrawal,
		isnull(sum(case when @SportType < 2 and bettype = 22004 then (winlost-actual_stake)* e.ActualRate2 else 0 end),0) as Bonus,
		isnull(sum(case when @SportType < 2 and bettype in (21001, 21002, 21003, 21004, 21005, 22005) then 1 else 0 end),0) as Adjustment,		
		isnull(sum(case when @SportType < 2 and bettype = 22001 then (winlost-actual_stake) * e.ActualRate2 else 0 end),0) * e.DepositPercent 
		+ abs(-isnull(sum(case when @SportType < 2 and bettype in (22002,22003) then (winlost-actual_stake) * e.ActualRate2 else 0 end),0)) * e.WithdrawalPercent		
		 as PSP
	from bodb02.dbo.bettrans b with (nolock) 
		inner join #ListCustId m with(nolock) on m.IbcCustID=b.custID 
	 inner join Exchange_Current e with (nolock)  ON m.Currency = e.Exchangeid
	where (@MonthDate is NULL OR DATEDIFF(m,@tdate,@today) = 0)  
		and b.winlostdate = @Today		    
		AND (Bettype < 99  or bettype in (21001, 21002, 21003, 21004, 21005, 22005,22001,22004))		
		AND bettype not in (71,72,73,74,75,76,77,78,79)
		and StatusID not in (101, 102, 103, 121,1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')
	Group by IBCUserName, m.username, m.RegisteredDate,e.DepositPercent,e.WithdrawalPercent

	Union All

	select IBCUserName, m.username, m.RegisteredDate, 
		isnull(sum(d.turnover * d.AffExRate), 0) as turnover, 
		isnull(sum(d.winlost * d.AffExRate), 0) as winlost,
		isnull(sum(d.deposit  * d.AffExRate), 0) as deposit,
		isnull(sum(d.withdrawal  * d.AffExRate), 0) as withdrawal,
		isnull(sum(d.bonus * d.AffExRate), 0) as bonus, 
		isnull(sum(d.Adjustment * d.AffExRate), 0) as Adjustment,
		isnull(sum(d.PSP  * d.AffExRate), 0) as PSP
	from MemberDaily d with (nolock)
		inner join #ListCustId m with(nolock) on m.IbcCustid = d.IbcCustid
	where (case when @MonthDate is NULL then--for searching all month  
				case when d.winlostdate < @Today then 1 else 0 end  
			else--for searching 1 month only  
				case when d.winlostdate between @fdate and @tdate then 1 else 0 end  
			end  
		) = 1
		and case when @sporttype = 0 then d.sporttype else @sporttype end = d.sporttype
		AND d.AffID = @AffID
		and (turnover > 0 or deposit > 0 or withdrawal>0 )
	group by IBCUserName, m.username, m.RegisteredDate
) as tmp
Group by  IBCUserName, Username, RegisteredDate
order by Username


GO
GRANT EXECUTE ON [dbo].[Aff_PlayersSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersSelDetail] TO [VNTeam]