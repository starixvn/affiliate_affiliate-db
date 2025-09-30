 declare	@Month int, 
	@Year int	
	

select @Month=06,@Year=2010

SET NOCOUNT ON

Declare @FirstDay smalldatetime,@LastDay smalldatetime,@TransType int,@SportsBookID int,@HorseRacingID int,@MarketingTransType int,@DeductionPercent float, @MinimumNegativeCommission float

select @MinimumNegativeCommission = 0.1

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')

Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0)),
	@TransType = 201,@MarketingTransType=204,@DeductionPercent=0.2 --201	Monthy Affiliate Transfer

if @LastDay > Current_TimeStamp
BEGIN
	SELECT 'The month is not completed yet. So you cannot transfer!' Result
	SELECT @FirstDay as FirstDay,@LastDay as LastDay
	RETURN
END

--Check group History data is inserted
if(not exists(select top(1) 1 from CommGroupHistory (nolock) where monthdate=@LastDay) 
   or not exists(select top(1) 1 from GroupSettingHistory (nolock) where monthdate=@LastDay)
   or not exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)
   or  not exists(select top(1) 1 from AffGroupHistory (nolock) where monthdate=@LastDay)
  )
 BEGIN
	SELECT 'All group setting history data for selected month have not been updated yet. Please update data first by executing Task_Aff_GroupSettingBackup @Month,@Year!' Result
	SELECT @FirstDay as FirstDay,@LastDay as LastDay
	RETURN
 END
/*IF EXISTS (select top(1) 1 from AffCommission with(nolock)
			where WinlostDate=@LastDay)
BEGIN
	SELECT 'Please check the data. Transfers have been done for this month!' Result	
	SELECT @FirstDay as FirstDay,@LastDay as LastDay
	RETURN
END
*/

--Get all Affiliates that is approved and IsClosed=false
declare /*@AFF_QMTurnOver money,*/@Status varchar(30)
select @Status='Approved'

/*select @AFF_QMTurnOver=cast(SValue as money)
 from SystemSettings (nolock)
 where SName ='AFF_QMTurnover'  
*/

--Create temp table to get summary data for each affiliate
CREATE TABLE #AffSummary
(
   /* [No] int IDENTITY(1,1),*/
	AffID int,
	Currency int,   
	GroupID int,
	SportID int,
	MemWinlost money,
	MemBonus money,
	MemAdjustment money,
	MemPSP money,
	Marketing money,
	MemDeposit money,
	MemTurnover money,
	Commission decimal(9,8),
	TotalQM int,  
	NetWinlost money,
	HasBonus bit,
	HasMarketing bit,
	HasAdjustment bit,
	HasPSP bit,
	BonusPercent float,
	MarketingPercent float,
	AdjustmentPercent float,
	PSPPercent float
	/*CONSTRAINT [PK_#AffSummary] PRIMARY KEY CLUSTERED (AffID,SportID)	*/
)


INSERT INTO #AffSummary(AffID,Currency,GroupID,SportID,MemWinlost,MemBonus,MemAdjustment,MemPSP,Marketing,MemDeposit,MemTurnover,TotalQM,HasBonus,HasMarketing,HasAdjustment,HasPSP,BonusPercent,AdjustmentPercent,MarketingPercent,PSPPercent)

Select t.AffID as AffID
	   ,t.Currency as Currency
	   ,t.GroupID as GroupID
	   ,r.SportType as SportID
	   ,sum(isnull(r.Winlost,0)) as MemWinlost
	   ,sum(isnull(r.Bonus,0)) as MemBonus
	   ,sum(isnull(r.Adjustment,0)) as MemAdjustment
	   ,sum(isnull(r.PSP,0)) as MemPSP
	   ,sum(isnull(r.Marketing,0)) as Marketing
	   ,sum(isnull(r.Deposit,0)) as MemDeposit
	   ,sum(isnull(r.Turnover,0)) as MemTurnover
	   ,sum(case when r.TurnOver>=s.QMTurnOver then 1 else 0 end) as TotalQM      
	   ,dbo.Aff_HasDeduction(t.GroupID,r.SportType,'Bonus',@LastDay) as HasBonus
	   ,dbo.Aff_HasDeduction(t.GroupID,r.SportType,'Adjustment',@LastDay) as HasAdjustment
	   ,dbo.Aff_HasDeduction(t.GroupID,r.SportType,'Marketing',@LastDay) as HasMarketing
	   ,dbo.Aff_HasDeduction(t.GroupID,r.SportType,'PSP',@LastDay) as HasPSP
	   ,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'Bonus',@LastDay) as BonusPercent
	   ,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'Adjustment',@LastDay) as AdjustmentPercent
	   ,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'Marketing',@LastDay) as MarketingPercent
	   ,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'PSP',@LastDay) as PercentPSP
FROM 
	 (select ai.AffId,coalesce(gh.GroupID,ai.GroupID) as GroupID,Currency
		   from AffInfo ai with (nolock)
				left join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and MonthDate=@LastDay
		   where ai.status=@Status and ai.AffID in (
											1205380,
1243033,
1244542,
1246216,
1246746,
1246854,
1248301,
1249544,
1252913,
1257975,
1264888,
1271808,
1273012,
1277208,
1298940,
1304410,
1322264,
1347151,
1397248,
1404361,
1430673,
1572607,
1574825,
1576218,
1590704,
1593279,
1677799,
1740768,
1755345,
1776148,
1823759,
1918174,
1925431,
1956137,
2007384,
92029266,
92029377,
92029496,
92029667,
92029679,
92029682,
92029696,
92029725,
92029829)
					
									  
	 
	  ) t      
	  left join 
	  (
		select IBCCustID,SportType,AffID
				,sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost
			   ,sum(isnull(Bonus,0) * isnull(AffExRate,1)) as Bonus
			   ,sum(isnull(Adjustment,0) * isnull(AffExRate,1)) as Adjustment
			   ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP
			   ,sum(isnull(Marketing,0) * isnull(AffExRate,1)) as Marketing
			   ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver
			   ,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit
		from MemberDaily md  (nolock) 
		where WinlostDate between @FirstDay and @LastDay and AffID in (
											1205380,
1243033,
1244542,
1246216,
1246746,
1246854,
1248301,
1249544,
1252913,
1257975,
1264888,
1271808,
1273012,
1277208,
1298940,
1304410,
1322264,
1347151,
1397248,
1404361,
1430673,
1572607,
1574825,
1576218,
1590704,
1593279,
1677799,
1740768,
1755345,
1776148,
1823759,
1918174,
1925431,
1956137,
2007384,
92029266,
92029377,
92029496,
92029667,
92029679,
92029682,
92029696,
92029725,
92029829)
		group by IBCCustID,SportType,AffID

	  ) r on r.AffID=t.AffID
	  left join SportType s (nolock) on s.SportID=r.SportType
  --where  r.SportType in (select distinct SportType from GroupSettingHistory (nolock) where GroupID=t.GroupID and MonthDate=@LastDay)
	  

group by t.AffID,t.GroupID, r.SportType,t.Currency
 
if(@@ROWCOUNT=0)
  begin
	 Select 'There was no data for selected month to transfer!' as Result
	 SELECT @FirstDay as FirstDay,@LastDay as LastDay  
	 drop table #AffSummary
	 return
  end
--Delete all Aff with all value=0
/*Delete #AffSummary
where MemTurnover=0 and MemWinlost =0 and	MemBonus=0 and MemAdjustment=0 and MemPSP=0 and Marketing=0*/

update #AffSummary with (rowlock,updlock)
set SportID=@SportsBookID
where SportID is null and MemTurnover=0 and MemWinlost =0 and	MemBonus=0 and MemAdjustment=0 and MemPSP=0 and Marketing=0

--Choose commission value and calculate Total Balance after deduction for each Affiliate and SportID

update a
set  a.NetWinlost=(-isnull(a.MemWinlost,0) 
				 - Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1)
				 -Cast(a.HasAdjustment as int) *  isnull(a.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) 
				-Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
				),
				
	 a.commission=isnull((select  top(1) Commission
						  from 
							(
								select isnull((select Commission
											  from GroupSettingHistory(nolock)
											  where GroupID=a.GroupID 
													and SportType=a.SportID
													and MonthDate=@LastDay
													and floor(
															  abs(
															   -isnull(a.MemWinlost,0) 
																 - Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1)
																 -Cast(a.HasAdjustment as int) *  isnull(a.MemAdjustment,0) *isnull(a.AdjustmentPercent,1) 
																-Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                 
																)
															) 
														between MinAmount and MaxAmount),0) as Commission
								union all                             
								  select isnull((select top(1) Commission 
													  from GroupSettingHistory(nolock)
													  where GroupID=a.GroupID 
															and SportType=a.SportID 
															and MonthDate=@LastDay
															and a.TotalQM between MinQM and MaxQM
												   ),0)
										   as Commission
							) t  
							order by t.Commission asc
					),0)
from #AffSummary a

update a
set a.Commission = @MinimumNegativeCommission
from #AffSummary a
where a.NetWinlost < 0 and a.Commission = 0
	  and a.SportID= @SportsBookID 
--select * from #AffSummary (nolock) order by AffID desc





--Insert transaction to AffTrans and AffCommission
declare @WinlostDate smalldatetime
select @WinlostDate=current_timestamp

begin transaction

BEGIN TRY
	---Delete all transfer from this month if exists

delete from  AffCommission 
where WinlostDate='2010-06-30 00:00:00' and AffID in (
1205380,
1243033,
1244542,
1246216,
1246746,
1246854,
1248301,
1249544,
1252913,
1257975,
1264888,
1271808,
1273012,
1277208,
1298940,
1304410,
1322264,
1347151,
1397248,
1404361,
1430673,
1572607,
1574825,
1576218,
1590704,
1593279,
1677799,
1740768,
1755345,
1776148,
1823759,
1918174,
1925431,
1956137,
2007384,
92029266,
92029377,
92029496,
92029667,
92029679,
92029682,
92029696,
92029725,
92029829

)
delete from AffTrans 
where TransType=201 and Transdate='2010-06-30 00:00:00'	
and AffID in (
  1205380,
1243033,
1244542,
1246216,
1246746,
1246854,
1248301,
1249544,
1252913,
1257975,
1264888,
1271808,
1273012,
1277208,
1298940,
1304410,
1322264,
1347151,
1397248,
1404361,
1430673,
1572607,
1574825,
1576218,
1590704,
1593279,
1677799,
1740768,
1755345,
1776148,
1823759,
1918174,
1925431,
1956137,
2007384,
92029266,
92029377,
92029496,
92029667,
92029679,
92029682,
92029696,
92029725,
92029829


)



	declare @Temp table(RefID int, AffID int, SportID tinyint) 
	Insert into AffCommission(AffID,GroupID,SportID,WinlostDate,QualifiedMember,Commission,AffWinlost,Status,MemberWinlost,MemberBonus,MemberAdjustment,MemberPSP,MemberSum,Marketing,HasBonus,HasAdjustment,HasMarketing,HasPSP,MemberDeposit,MemberTurnover)
	output inserted.RefID,inserted.AffID,inserted.SportID into @Temp 
	select AffID,GroupID,SportID,@LastDay,TotalQM,Commission 
		  ,(NetWinlost * isnull(Commission,0)-Cast(HasPSP as int)* isnull(MemPSP,0)*isnull(PSPPercent,0)) 
		  , @Status
		  ,MemWinlost
		  ,MemBonus
		  ,MemAdjustment
		  ,MemPSP
		  ,-NetWinlost
		  ,(Cast(HasMarketing as int) *  abs(isnull(MemWinlost,0)) * isnull(MarketingPercent,1))
		  ,HasBonus,HasAdjustment,HasMarketing,HasPSP,MemDeposit,MemTurnover 
	from #AffSummary a (nolock)
	
	update d
	set d.RelNo=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.SportID=@SportsBookID)
   from AffCommission d with (rowlock,updlock)       
   where d.WinlostDate=@LastDay

	insert into AffTrans(AffID,TransDate,CompletedDate,Amount,Status,Description,Creator,Currency,TransType)
	select a.AffID,@LastDay,@WinlostDate,sum(a.NetWinlost * isnull(a.Commission,0)-Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,0)),@Status, 'Monthly Earning',
		 148,a.Currency,@TransType
	from #AffSummary a (nolock)   
	group by a.AffID,a.Currency
	

	update d
	set d.RefID=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.SportID=@SportsBookID)
   from AffTrans d with (rowlock,updlock)       
   where d.TransDate=@LastDay and d.TransType=@TransType /*in (@TransType,@MarketingTransType)*/
   /*Reupdate table AffDaily  
	  MemMarketing = Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
	  AffWinlost= -MemWinlost * commission
	  HouseWinlost=-MemWinlost * (1-commission)
	  AffNetWinlost=(-isnull(a.MemWinlost,0) 
				 - Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1)
				 -Cast(a.HasAdjustment as int) *  isnull(a.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) 
				-Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
				) * commission - Cast(HasPSP as int)* isnull(MemPSP,0)*isnull(PSPPercent,0)
	  HouseNetWinlost=
   */
		
	   
   update ad 
	 set ad.MemMarketing=Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0) ,
		ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),
		ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),
		ad.AffNetWinlost=(-isnull(ad.MemWinlost,0) 
						- Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)
						-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) 
					   -Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
					   ) * isnull(a.commission,0) - Cast(isnull(a.HasPSP,0) as int)* isnull(ad.MemPSP,0)*isnull(PSPPercent,0),
					   
	   ad.HouseNetWinlost= (-isnull(ad.MemWinlost,0) 
						- Cast(isnull(a.HasBonus,1) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)
						-Cast(isnull(a.HasAdjustment,1) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) 
					   -Cast(isnull(a.HasMarketing,1) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
					   ) * (1-isnull(a.commission,0)) - Cast(isnull(a.HasPSP,1) as int)* isnull(ad.MemPSP,0)* (1-isnull(PSPPercent,0))              
				
	  from AffDaily ad with (rowlock,updlock)  
	  left join #AffSummary a with (nolock) on a.AffID=ad.AffID and a.SportID=ad.SportID     
   where datediff (mm,ad.Winlostdate, @FirstDay)=0  
   
   
   
END TRY

BEGIN CATCH
	rollback transaction	
	drop table #AffSummary
	PRINT ERROR_MESSAGE()
	RETURN
END CATCH

commit transaction

drop table #AffSummary