ALTER PROCEDURE [dbo].[Aff_ReportQM]
	@AffName varchar(50) = NULL,
	@PreferredLanguage varchar(11) = null,
	@Month int,
	@Year int,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT    
AS

/*
Created: 20091213@Peter
Task : Get Qualifying member report for all affiliates.
DB: DB052.Affiliate_12BET
Original: 
Revisions:
	- 20110523@Henry: change bettype to new range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120508@Johnny: Add Casino 
	- 20120606@Peter : Exclude waiting tickets
Param's Explanation:
	
*/
SET NOCOUNT ON

Declare @FirstDay smalldatetime,@LastDay smalldatetime,@SportsBookID int, @HorseRacingID int, @CasinoID int, @MaxWinlostDate smalldatetime, @NoComGroupID int
		
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing'), @CasinoID = dbo.Aff_GetSportID('Casino')

Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
 --Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))

select @MaxWinlostDate=max(WinlostDate) from AffCommission with (nolock)

select @NoComGroupID = GroupID from CommGroup with (nolock) where GroupName = 'NoCommission'


select @AffName= '%' + Coalesce(@AffName, '') + '%'

select @NRows=count(1)    
FROM  AffInfo ai with (nolock)  
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE ai.Username like @AffName
	and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
	and ai.ApprovedDate < @LastDay
--Exclude all closed affs 
	and (ai.IsClosed=0 or ai.GroupID<>  @NoComGroupID)
	and ai.Status='approved'  


if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
	
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
		
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30))

insert into @TempAff
select m.AffId, m.username
from  
	(select ROW_NUMBER() OVER(ORDER BY ai.AffId) AS TheCount,  
		ai.AffID, ai.UserName, ad.PreferredLanguage
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
	where ai.Status = 'Approved'
		and ai.ApprovedDate < @LastDay
		--Exclude all closed affs 
		and (ai.IsClosed=0 or ai.GroupID<>  @NoComGroupID)
		and ai.Username like @AffName  
		and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
	) m
where m.TheCount between @RowStart and @RowEnd


if(@LastDay<=@MaxWinlostDate) --Get Data from AffCommission
BEGIN
		 
	 select a.AffID,a.username as username, Sum(isnull(m.SPQM, 0)) as SPQM, Sum(isnull(m.HRQM, 0)) as HRQm, Sum(isnull(m.CAQM, 0)) as CAQM
	 from	 
		@TempAff a left join
		(
			select AffId, isnull(QualifiedMember,0) as SPQM, 0 as HRQM, 0 as CAQM
			from AffCommission with (nolock)
			where WinlostDate = @LastDay   
				and SportID=@SportsBookID
			
			Union All
			
			select AffId, 0 as SPQM, isnull(QualifiedMember,0) as HRQM, 0 as CAQM
			from AffCommission with (nolock)
			where WinlostDate = @LastDay   
				and SportID=@HorseRacingID
			
			Union All
			
			select AffId, 0 as SPQM, 0 as HRQM, isnull(QualifiedMember,0) as CAQM
			from AffCommission with (nolock)
			where WinlostDate = @LastDay   
				and SportID=@CasinoID
		)m  on m.AffID=a.AffID	 
	Group By a.AffID,a.username
	 order by a.AffId 

END
else --Calculate data for uncalculated month
BEGIN
	  
	DECLARE @MemList TABLE(IBCCustId int, AffId int, ActualRate2 float)	
	Declare  @QmTurnOverSP money, @QmTurnOverHR money, @QmTurnOverCA money, @QMDepositCA money, @CurrDate smalldatetime
		
	select @CurrDate =  convert(varchar(10),current_timestamp,120),
		@LastDay = (case when @LastDay >= @CurrDate then dateadd(d, -1, @CurrDate) else @LastDay end)
	
	select @QmTurnOverSP=QMTurnOver
	from SportType (nolock) where  SportID=@SportsBookID
	
	select @QmTurnOverHR=QMTurnOver
	from SportType (nolock) where  SportID=@HorseRacingID

	select @QmTurnOverCA=QMTurnOver, @QMDepositCA = QMDeposit
	from SportType (nolock) where  SportID=@CasinoID

	if (@FirstDay > @CurrDate)--The month is incorrect
	Begin
		select AffID, username, 0 as SPQM, 0 as HRQm, 0 as CAQm, 0 as TotalQM
		from @TempAff
		Return
	End
	
	
	insert into @MemList
	Select IbcCustId, mi.AffId, ActualRate2
	From 
		MemberInfo mi with (nolock)
		inner join @TempAff a on mi.AffId = a.AffId
		inner join Exchange_Current e with (nolock) on mi.Currency = e.ExchangeId
	where mi.IsRemoved = 0
	
	
	--Calculate Turnover for SP & HR & CA
	
	 select a.AffID,a.username as username,isnull(sp.TotalQM,0) as SPQM, isnull(hr.TotalQM,0) as HRQm, isnull(ca.TotalQM,0) as CAQm
	 from @TempAff a	 	 
		 left join
			(
				Select t.AffID as AffID
					  ,sum(case when t.TurnOver>=@QmTurnOverSP then 1 else 0 end) as TotalQM  
				FROM  
					(
					Select IBCCustID,AffID
						   ,sum(isnull(TurnOver,0)) as TurnOver
					From
						(
						select IBCCustID,AffID--Get data from MemberDaily for SP
							   ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver			   
						from MemberDaily md  (nolock) 
						where WinlostDate between @FirstDay and @LastDay and SportType=@SportsBookID and  AffID in (Select AffID from @TempAff) 
						group by IBCCustID,AffID
						
						Union all
						
						Select m.IbcCustId, m.AffId--Get data from bettrans for SP
							, Sum(isnull(abs(b.stake), 0) * isnull(m.ActualRate2, 0)) as TurnOver
						From 
							@MemList m
							inner join bodb02.dbo.Bettrans b with (nolock) on m.IBCCustId = b.CustId 
						where datediff(m, @LastDay, @CurrDate) = 0 
							and WinlostDate = @CurrDate
							and bettype < 19000 
							and bettype not in (31,32,33,41,42,43)
							 and bettype not between 71 and 120 --Not include Casino and Number Game
							and StatusID not in (101, 102, 103, 121,1)
							--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')
						Group by m.IbcCustId, m.AffId
						) a
					Group by IBCCustID,AffID
				  )t
				 group by t.AffID		     
			 ) sp on sp.AffID=a.AffID
		 left join
			 (
				 Select t.AffID as AffID
					  ,sum(case when t.TurnOver>=@QmTurnOverHR then 1 else 0 end) as TotalQM  
				FROM  
					(					
					Select IBCCustID,AffID
					   ,sum(isnull(TurnOver,0)) as TurnOver
					From
						(
						select IBCCustID,AffID--Get data from MemberDaily for HR
							   ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver			   
						from MemberDaily md  (nolock) 
						where WinlostDate between @FirstDay and @LastDay and SportType=@HorseRacingID and  AffID in (Select AffID from @TempAff)
						group by IBCCustID,AffID
					
						Union all
						
						Select m.IbcCustId, m.AffId--Get data from bettrans for HR
							, Sum(case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(abs(stake),0)/2 else isnull(abs(stake),0) end * isnull(m.ActualRate2, 0)) as TurnOver
						From 
							@MemList m
							inner join bodb02.dbo.Bettrans b with (nolock) on m.IBCCustId = b.CustId 
						where datediff(m, @LastDay, @CurrDate) = 0 
							and WinlostDate = @CurrDate
							and bettype in (31,32,33,41,42,43)
							and StatusID not in (101, 102, 103, 121,1)
							--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')
						Group by m.IbcCustId, m.AffId
						) a
					Group by IBCCustID,AffID
				  )t
				  group by t.AffID
			  
			  ) hr on hr.AffID=a.AffID	
		left join
			 (
				 Select t.AffID as AffID
					  ,sum(case when t.TurnOver>=@QmTurnOverCA and t.Deposit >= @QMDepositCA then 1 else 0 end) as TotalQM  
				FROM  
				(	
					select IBCCustID,AffID--Get data from MemberDaily for HR
							,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver			   
							,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit			   
					from MemberDaily md  (nolock) 
					where WinlostDate between @FirstDay and @LastDay and SportType=@CasinoID and  AffID in (Select AffID from @TempAff)
					group by IBCCustID,AffID
				  )t
				  group by t.AffID
			  
			  ) ca on ca.AffID=a.AffID	
	order by a.AffId      
END

GO
GRANT EXECUTE ON [dbo].[Aff_ReportQM] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportQM] TO [VNTeam] 