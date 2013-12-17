ALTER PROCEDURE [dbo].[Aff_CasinoImportData]	
	@AdminID int,
	@ImportDate smalldatetime,
	@XmlData XML,
	@IsReplaceData bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*3
	Task : Import casino transactions from excel file into 2 tables, memberdaily and AffDailySummary
	Author : Johnny@20110801
	DB: DB052.Affiliate_12BET
	Original: [Aff_CasinoImportData]
	Revisions: 
		- 20120409@Johnny:
			+ link: http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320
			+ Desc: import monthly Casino data in excel file to Affiliate_12BET DB when a month is completed to calculate Casino Commission
		- 20121211@Johnny: only import casino data for affiliate has been approved Casino before the date import data
*/
BEGIN  
SET NOCOUNT ON  
   
EXEC [dbo].[Aff_Con_CheckPermission]  
		@custid=@AdminID,
		@funcname='[ImportData]',  
		@System = 'AFFILIATE',  
		@ErrCode=@ErrCode output,  
		@ErrMsg=@ErrMsg output 

if @ErrCode <> 0
	return

--Import new Data here
DECLARE @TempTrans TABLE(DateImport smalldatetime, UserName nvarchar(30), Currency nvarchar(50), Turnover money, Winlost money, Deposit money, Bonus money)--Convert XML to data table
DECLARE @TempDateImport TABLE(DateImport smalldatetime)--Store all date
DECLARE @SuccessTrans TABLE(DateImport smalldatetime, UserName nvarchar(30), Currency nvarchar(50), Turnover money, Winlost money, Deposit money, Bonus money)--List trans insert successfully
DECLARE @Exchange Table(Date smalldatetime, ExchangeId int, Currency nvarchar(50), MemberExRate float, AffExRate float)--List Exchange rate on last date of previous month

Declare @MinDateImport smalldatetime, @CasinoId int

select @CasinoId = dbo.Aff_GetSportID('Casino')

insert into @TempTrans--Convert xml to table
select 	 
	DateImport,
	Username,
	Currency,
	Turnover,
	Winlost,
	Deposit,
	Bonus
from
	(Select
		[Table].[Column].value('./@date', 'smalldatetime') as [DateImport],
		[Table].[Column].value('./@username', 'varchar(100)') as [Username],
		[Table].[Column].value('./@currency', 'nvarchar(50)') as [Currency],
		[Table].[Column].value('./@turnover', 'float') as [Turnover],
		[Table].[Column].value('./@winlostaff', 'float') as [Winlost],
		[Table].[Column].value('./@deposit', 'float') as [Deposit],
		[Table].[Column].value('./@bonus', 'float') as [Bonus]
	from @XmlData.nodes('/root/trans') as [Table]([Column])
	) as tmp

insert into @TempDateImport(DateImport)
select distinct DateImport from @TempTrans

select @MinDateImport = (select min(DateImport)
						from @TempDateImport)
select @MinDateImport = convert(varchar(10), @MinDateImport, 120)

insert into @Exchange--Get List Exchange
select DateImport as Date, ex.ExchangeId, Currency, ActualRate as MemberExRate, ActualRate2 as AffExRate
From Exchange ex with (nolock)
	inner join 
	(
		select DateImport, ExchangeID, max(UpdatedTime) as UpdatedTime
		from Exchange with (nolock) 
			inner join @TempDateImport on UpdatedTime <= DateImport
		group by DateImport, ExchangeID
	) ex1 on ex.ExchangeId = ex1.ExchangeId and ex.UpdatedTime = ex1.UpdatedTime
ORDER BY currency

--Check Monthly transfer or not
if exists(select 1 from AffTrans (nolock) where datediff(m, TransDate, @MinDateImport) = 0 and Transtype = 201)
Begin
	Select @ErrCode = 10101,
		@ErrMsg = 'You cannot import Casino transaction because monthly transfers for the month ' + convert(varchar(3), @MinDateImport) + ' ' + convert(varchar(4), year(@MinDateImport)) +  ' has been completed!'
	return
End

if(@IsReplaceData = 0)--Check to know donot replace data but there is data in memberdaily
begin
	--Check Data whether Casino data import or not.
	if exists(select 1 from MemberDaily (nolock )
				where winlostdate in (select DateImport from @TempDateImport) and sporttype = @CasinoId)
	Begin
		Select @ErrCode = 10100,
			@ErrMsg = 'You cannot import Casino transaction! Because data has been imported already!'
		return
	End
End
	

BEGIN TRANSACTION 
	if(@IsReplaceData = 1)--If Replace Data => delete old data and import new data
	Begin
		delete MemberDaily
		where winlostdate in (select DateImport from @TempDateImport) and sporttype = @CasinoId
		
		Delete AffDaily
		where winlostdate in (select DateImport from @TempDateImport) and SportId = @CasinoId

		Delete AffDailySummary
		where winlostdate in (select DateImport from @TempDateImport) and SportID = @CasinoId

		IF @@Error <> 0 
		begin
			SELECT @ErrMsg = 'There was an error when updating data.', @ErrCode = 1008
			ROLLBACK TRANSACTION
			return
		end
	End

--return

	--Insert transactions to MemberDaily
	insert into MemberDaily(
		[WinlostDate]
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
		,[MemOddsFee]
		,[MemWinlostFake]
		,[MemPLayTechFee]
		)
		
	select t.DateImport as WinlostDate, 
		IBCCustId, 
		3 as SportType, 
		m.Currency,
		t.Deposit,
		0 as Withdrawal,
		t.Bonus,		
		0 as Adjustment,
		Turnover,
		0 as Outstanding,
		-Winlost,
		0 as AWinlost,
		0 as ABonus,		
		ex.AffExRate,--Get AffRate here
		ex.MemberExRate,--Get MemberExrate here
		0 as DrawGame,
		0 as PSP,
		abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'Marketing',t.DateImport),0) as Marketing,
		AffId,
		0 as MemOddsFee,
		-(-Winlost
			- (abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'PlayTech Royalties',t.DateImport),0))
			-  (abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'Marketing',t.DateImport),0))
		)as MemWinlostFake,

		abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'PlayTech Royalties',t.DateImport),0) as MemPLayTechFee
	from @TempTrans as t
		inner join 
		(
			Select IBCCustId, m.Username, m.Currency, m.AffId
			From
				MemberInfo m with(nolock) -- or t.Username = m.Username
				inner join AffInfo a with (nolock) on m.AffId = a.AffId
			Where a.CasinoJoinedDate is not null 
				and m.RegisteredDate >= a.CasinoJoinedDate
		)as m on '12bet$' + t.Username = m.Username
		inner join @Exchange as ex on m.Currency = ex.ExchangeID and t.DateImport = ex.[Date]
		--Comment for check currency--and t.Currency = ex.Currency	
	--order by t.DateImport

	--Insert Data into Affiliate Daily
	Insert into AffDaily([AffID]
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
		   ,[MemOddsFee]
		   ,[MemPLayTechFee]
		   )

	select      d.AffID as AffID,      
				d.Currency as Currency,       
				d.Winlostdate as Winlostdate,       
				d.SportType as SportID,      
				d.AffExRate as Exrate2,       
				SUM(isnull(d.Deposit, 0)) as MemDeposit,   
				0 as MemWithdrawal,       
				SUM(isnull(d.Turnover, 0)) as MemTurnover,       
				SUM(isnull(d.Bonus, 0)) as MemBonus,    
				0 as MemAdjustment,    
				0 as MemMarketing,    
				0 as MemPSP,        
				SUM(isnull(d.Winlost, 0)) as MemWinLost,        
				0 as AffWinLost,      
				-SUM(d.Winlost) as HouseWinLost,        
				0 as AffNetWinlost,      
				0 as HouseNetWinLost,	
				0 as MemWinlostFake,      
				0 as MemOddsFee,
				0 as MemPLayTechFee
		from MemberDaily d with (nolock) 
			--inner join @TempTrans on t.[Date] = d.WinlostDate
		where SportType = @CasinoId and winlostdate in (select DateImport from @TempDateImport)
		GROUP BY d.AffID,d.Winlostdate, d.Currency, d.SportType,d.AffExRate   
	--Update AffDaily data for fee and winlost for company and fake winlost

update AffDaily with (rowlock,updlock)

set 
	MemPLayTechFee= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0),
	[MemMarketing]= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0),
	--MemOddsFee= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0),  
	HouseNetWinLost=HouseWinLost
						- isnull(MemBonus,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Casino Bonus',Winlostdate),0)   
						- isnull(MemWinlost,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
						- isnull(MemWinlost,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0),
	MemWinlostFake=-(-isnull(MemWinlost,0)
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)							 
					)
						
	where winlostdate in (select DateImport from @TempDateImport) and SportID = @CasinoId

	

	--Insert Data into Affiliate Summary Daily
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
		   ,[MemWinlostFake]
		   ,[MemPLayTechFee]	   
		   )

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
			   ,0 as MemPLayTechFee
	from AffDaily(nolock)
	where winlostdate in (select DateImport from @TempDateImport) and SportID = @CasinoId
	group by AffID,Winlostdate,SportID


update AffDailySummary with (rowlock,updlock)
set MemMarketing=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate),         
	MemWinlostFake=-(-isnull(MemWinlost,0)
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
					 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)							 
					),
   
	 HouseNetWinlost=(
						-MemWinlost
						-MemBonus * dbo.Aff_GetDeductionPercent(AffID,SportID,'Bonus',WinlostDate)
						 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
						-abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)							 
					 )
			
	
 where winlostdate in (select DateImport from @TempDateImport) and SportID = @CasinoId 
  
  
  
 /*update last MemWinlostFake of last transaction date for each acount
	For example: Affiliate 1 : last day =28/11
				Affiliate 2 : last day= 29/11
				Affiliate 3 : last day= 31/11								
 */
declare @minFirstDayOfImportDate datetime

select @minFirstDayOfImportDate=[dbo].[Aff_GetFirstDayOfMonth](min(DateImport))
from @TempDateImport

declare @temp table(affid int,totalWinlost money, playTechFeePercent float,marketingPercent float,WLFake money,maxWinlostDate smalldatetime,previousMaxWinlostDate smalldatetime,firstday smallDateTime)

insert into @temp(Affid,maxWinlostDate)
select affid,max(winlostdate)
from AffDailySummary a (nolock)
    cross apply @TempDateImport t
where a.winlostdate >= @minFirstDayOfImportDate
	and datediff(m, winlostdate, t.DateImport) = 0 
    
	--winlostdate in (select DateImport from @TempDateImport) 
	and a.SportID = @CasinoId 
group by affid,month(winlostdate),year(winlostdate)

update t
set t.previousMaxWinlostDate=isnull(
                    (select max(winlostdate) 
                     from AffDailySummary (nolock) 
                     where SportID=3 and winlostdate<t.maxWinlostDate 
                     and datediff(m,winlostdate,t.maxWinlostDate)=0
                     and affid=t.affid
                      ),t.maxWinlostDate
                             
                      )
   ,t.firstday=[dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate)    
   ,t.playTechFeePercent=dbo.Aff_GetDeductionPercent(AffID,@CasinoId,'PlayTech Royalties',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))
   ,marketingPercent=dbo.Aff_GetDeductionPercent(AffID,@CasinoId,'Marketing',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))

from @temp t

--reupdate WinlostFake of previousMaxWinlostDate for MemberDaily, AffDaily, AffDailySummary
/*
Update md
set md.[MemWinlostFake]=-(-md.Winlost
			- (abs(md.Winlost) * isnull(dbo.Aff_GetDeductionPercent(md.AffID,@CasinoId,'PlayTech Royalties',md.WinlostDate),0))
			-  (abs(md.Winlost) * isnull(dbo.Aff_GetDeductionPercent(md.AffID,@CasinoId,'Marketing',md.WinlostDate),0))
		)
from MemberDaily md with (rowlock,updlock)
     inner join @temp t on t.affid=md.AffID and t.previousMaxWinlostDate=md.WinlostDate

where md.SportType=@CasinoId

update ad

set ad.MemWinlostFake=-(-isnull(ad.MemWinlost,0)
					 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,@CasinoId,'PlayTech Royalties',ad.Winlostdate),0)
					 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,@CasinoId,'Marketing',ad.Winlostdate),0)							 
					)
from AffDaily ad with (rowlock,updlock)						
    inner join @temp t on t.affid=md.AffID and t.previousMaxWinlostDate=ad.WinlostDate 
where ad.SportID = @CasinoId*/

update ad

set ad.MemWinlostFake=-(-isnull(ad.MemWinlost,0)
					 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,@CasinoId,'PlayTech Royalties',ad.Winlostdate),0)
					 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,@CasinoId,'Marketing',ad.Winlostdate),0)							 
					)
from AffDailySummary ad with (rowlock,updlock)						
    inner join @temp t on t.affid=ad.AffID and t.previousMaxWinlostDate=ad.WinlostDate 
where ad.SportID = @CasinoId

	


update d

set d.totalWinlost=isnull(c.totalwinlost,0)
   ,d.WLFake=isnull(c.memWinlostFake,0)
from @temp d
  left join
   ( select t.affid,sum(ad.memwinlost) totalwinlost,sum(ad.memWinlostFake) memWinlostFake
	  from AffDailySummary ad (nolock) 
			inner join @temp t on t.AffID=ad.AffID
	  where ad.WinlostDate between t.firstday and  t.previousMaxWinlostDate
			and ad.SportID=@CasinoId
	  group by t.Affid     
  ) c on c.AffID=d.AffID   




--select * from @temp

update d
	Set MemWinlostFake=-(-(d1.totalwinlost + d.memwinlost) - abs (d1.totalwinlost + d.memwinlost) * (d1.playTechFeePercent+d1.marketingPercent))- d1.WLFake
from AffDailySummary d with (rowlock,updlock)
	 inner join @temp d1 on d1.affid=d.affid and  d1.maxWinlostDate=d.winlostdate 			 
where d.sportid=@CasinoId
		 and d1.previousMaxWinlostDate < d1.maxWinlostDate
	IF @@Error <> 0 
	begin
		SELECT @ErrMsg = 'There was an error when updating data.', @ErrCode = 1008
		ROLLBACK TRANSACTION
		return
	end

COMMIT TRANSACTION
	
--List successs transactions
insert into @SuccessTrans
select 
	md.winlostdate as  DateImport,
	replace(m.Username, '12bet$', ''),
	ex.Currency,
	Turnover,
	Winlost,
	Deposit,
	Bonus
from MemberDaily md with (nolock)
	inner join MemberInfo m with (nolock) on md.IBCCustId = m.IBCCustID
	inner join Exchange_Current ex with (nolock) on md.Currency = ex.ExchangeId
where sporttype = @CasinoId and WinlostDate in (Select DateImport From @TempDateImport)


--Return list success transaction
select DateImport, Username, Currency, Turnover, Winlost, Deposit, Bonus
from @SuccessTrans 
order by DateImport

--List Failed Transaction
select 
	DateImport,
	Username, 
	(case Currency when 'CNY' then 'RMB'
			when 'USD' then 'US$'
			when 'EUR' then 'EURO'
			when 'VDO' then 'VND'
			when 'THB' then 'TB'
			when 'RUP' then 'IN'
			when 'MYR' then 'RM'
			else Currency end
	) as Currency, 
	Turnover, 
	Winlost,
	Deposit,
	Bonus
from @TempTrans
where Username not in (select Username from @SuccessTrans)
order by DateImport


END  

GO
GRANT EXECUTE ON [dbo].[Aff_CasinoImportData] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CasinoImportData] TO [VNTeam] 
