ALTER PROCEDURE [dbo].[Task_Aff_MemberDailySummaryForAff]
	@winlostdate datetime,
	@AffId int
AS
/*
	Created: 20090701@Peter
	Task : Summary data from 12BET Affiliates members, This task will occurs every 2 hours and every day at 00:00
	DB: DB052.Affiliate_ZZun

	Revisions:				
		         20100527@Peter: Use new StatusID column instead of Status column on bettrans table   
		         20100923@Peter : Change new way to calculate PSP fee , 
		                   *** we cannot recalculate the PSP before 1 Oct 2010 (coz this time we use new formula to calculate)
		                   + Before 1/4/2010 
										MemWinlostFake=MemWinlost
		                   + From 1/4/2010-> 30/9/2010 
		                   
										MemWinlostFake = MemWinlost * NetPercentReceive
										Select @MemWinlost=[dbo].[Aff_GetMemberWinlost] (@AffID, @SportsBookID, @monthdate)
										select @NetPercentReceived = (case when @MemWinlost > 0 then 1 + @Percent else 1 - @Percent end)
                            + From 1/10/2010:
                                        MemWinlostFake=(case when MemberWinlost>0 then MemberWinlost * (1 + @MarketingPercent + @OddsFeePercent) - PSP
	       												 else  MemberWinlost * (1 - @MarketingPercent - @OddsFeePercent) - PSP
													  	end )
                 20101228@Henry: change bettype to new range           

	Param's Explanation:
	• @winlostdate: The data need to summary
*/

-- HARD CODE: not cal before 1st OCt 2010 (New formula is lauched)
SET NOCOUNT ON

--IF @Winlostdate < '1 Oct 2010' or @Winlostdate>current_timestamp RETURN

Select @winlostdate= CONVERT(varchar(10), @winlostdate, 120)
/*if (not exists (SELECT top(1) winlostdate FROM DB06.bodb_report.dbo.rptDepWinlost with(nolock) WHERE winlostdate = @winlostdate))
  RETURN*/

DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME,@SysCurrency varchar(5)

  
SELECT @BalanceUpDay = winlostdate FROM bodb02.dbo.Bettrans WITH(NOLOCK) WHERE bettype = 100 and matchid = 0 and custid = 3  
SELECT @MoveBetsDay = max(winlostdate) FROM bodb02.dbo.Bettrans14 WITH(NOLOCK)  

/*
	+ When we remove member from the system -> member will be not counted since RemovedDate
    + When we move member from Affiliate A to Affiliate B if the history winlostdate we will get list of member from MemberDaily, otherwise we will get from MemberInfo
*/

CREATE TABLE #MemberInfo
(
	UserName varchar(30) primary key,
	IBCCustID int ,	
	AffID int,
	recommend int,
	Currency varchar(5)
)  

DECLARE @AffExchange table(ExchangeID int,Currency varchar(5) primary key,USD float,EUR float,CNY float,UUS float, DepositPercent float,WithdrawalPercent float)

if(datediff(d,@Winlostdate,current_timestamp)=0)
 BEGIN
	INSERT INTO @AffExchange(ExchangeID,Currency,USD,EUR,CNY,UUS,DepositPercent,WithdrawalPercent)	
    SELECT ExchangeID,Currency,USD,EUR,CNY,UUS,DepositPercent,WithdrawalPercent     
    from Exchange e with (nolock)   
		
	Insert into #MemberInfo(IBCCustID,UserName,AffID,recommend,currency)
	select IBCCustID,UserName,AffID,recommend,currency
	from MemberInfo m with(nolock)
	where IsRemoved=0
	 and CreatedDate is not null	
	 and AffID=@AffID	 
      
 END
else
  BEGIN
   /*
		****** Note: We must insert at least on row for each currency into Exchange table
                     when new DB is launched
  */
		INSERT INTO @AffExchange(ExchangeID,Currency,USD,EUR,CNY,UUS,DepositPercent,WithdrawalPercent)	
        SELECT e.ExchangeID,e.Currency,e.USD,e.EUR,e.CNY,e.UUS,DepositPercent,WithdrawalPercent     
        from ExchangeDaily e with (nolock)
			inner join Exchange e1 (nolock) on e1.Currency=e.currency	
        where e.Date=@winlostdate
		
		--only members have transaction on that day
		Insert into #MemberInfo(IBCCustID,UserName,AffID,recommend,currency)
		select IBCCustID,UserName,AffID,recommend,currency
		from MemberInfo m with(nolock)
		where CreatedDate is not null	 
		and datediff(d,CreatedDate,@WinlostDate)>0
		and username not in (select username from MemberRemoval where datediff(d,RemovedDate,@WinlostDate)>0)
		and AffID=@AffID	

		--reupdate AffID in case we move member from Affiliate A to Affiliate B
		update mi
		set mi.AffID=m1.AffID
		from  #MemberInfo mi with (rowlock,updlock)
		inner join (
					select distinct IBCCustID,UserName,AffID,currency
					from MemberDaily m with(nolock)
					where WinlostDate=@Winlostdate and AffID=@AffID	
		)m1 on m1.username=mi.username 
		where mi.AffID<>m1.AffID		

  END


declare  @SystemCurrency varchar(5)
Select @SystemCurrency=SValue
from SystemSettings (nolock)
where Type='Meta' and SName='SystemCurrency'	
    
CREATE TABLE #Data(
	[UserName] varchar(30),	
	[ProductID] tinyint,
	[AffID] int,
	[IBCCustID] int,
	[Currency] varchar(5) ,
	[Turnover] money,
	[Outstanding] money,
	[Winlost] money,
	[DrawGame] money
 CONSTRAINT [PK_MemberDaily_temp] PRIMARY KEY  
(
	[UserName] ASC,	
	[ProductID] ASC
)
)
/*
	Sportbooks Bettype: bettype<=30 or bettype between 81 and 98
	Casino Bettype : Bettype between 71 and 80
					Age_Rpt_WinLossDetail_Ag
					Age_Rpt_Outstanding_Ag
	Horse Racing Bettpe : Bettype between 31 and 50
	Finance Bettype : Bettype between 51 and 70	
*/


IF @Winlostdate > @MoveBetsDay 
  BEGIN
	 insert into #Data ([UserName]           
           ,[ProductID]
           ,[AffID]
           ,[IBCCustID]
           ,[Currency]                   
           ,[Turnover]
           ,[Outstanding]
           ,[Winlost]
           ,[DrawGame]
           )

		select	m.UserName,				
				sp.ProductID as ProductID,
				m.AffID,
				m.IBCCustID,
				m.currency,	
				isnull(sum(case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(stake,0)/2 
								else isnull(stake,0) end),0) as Turnover,
				isnull(sum(case when ruben=0 then isnull(actual_stake,0) else 0 end),0) as Outstanding,
				isnull(sum(case when ruben=1 then isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0) else 0 end),0) as Winlost,
				isnull(sum(case when StatusID=111/*status in ('DRAW')*/ then isnull(stake,0) else 0 end),0) as DrawGame											
		from #MemberInfo m with (nolock)	
		JOIN Product sp with (nolock) on 1=1			
		LEFT JOIN bodb02.dbo.bettrans b with (nolock) on b.CustID=m.IBCcustid		    
		where winlostdate = @winlostdate		     
			 and StatusID not in (101, 102, 103, 121)			 			 	
			and b.bettype in (select val from dbo.strSplit(sp.BettypeList,','))					   
		group by m.UserName,m.IBCCustID, m.currency,sp.ProductID,              
                m.AffID
		
	END

ELSE IF @Winlostdate < @BalanceUpDay
   BEGIN
		 insert into #Data ([UserName]           
           ,[ProductID]
           ,[AffID]
           ,[IBCCustID]
           ,[Currency]                   
           ,[Turnover]
           ,[Outstanding]
           ,[Winlost]
           ,[DrawGame]
           )
		select	m.UserName,				
				sp.ProductID as ProductID,
				m.AffID,
				m.IBCCustID,
				m.currency,	
				isnull(sum(case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(stake,0)/2 
								else isnull(stake,0) end),0) as Turnover,
				isnull(sum(case when ruben=0 then isnull(actual_stake,0) else 0 end),0) as Outstanding,
				isnull(sum(case when ruben=1 then isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0) else 0 end),0) as Winlost,
				isnull(sum(case when StatusID=111/*status in ('DRAW')*/ then isnull(stake,0) else 0 end),0) as DrawGame											
		from #MemberInfo m with (nolock)	
		JOIN Product sp with (nolock) on 1=1			
		LEFT JOIN DB06.bodb_archive.dbo.bettrans_bk b with (nolock) on b.CustID=m.IBCcustid		    
		where winlostdate = @winlostdate		     
			 and StatusID not in (101, 102, 103, 121)			 			 	
			and b.bettype in (select val from dbo.strSplit(sp.BettypeList,','))					   
		group by m.UserName,m.IBCCustID, m.currency,sp.ProductID,              
                m.AffID
   END 
ELSE
   BEGIN
		insert into #Data ([UserName]           
           ,[ProductID]
           ,[AffID]
           ,[IBCCustID]
           ,[Currency]                   
           ,[Turnover]
           ,[Outstanding]
           ,[Winlost]
           ,[DrawGame]
           )
		select	m.UserName,				
				sp.ProductID as ProductID,
				m.AffID,
				m.IBCCustID,
				m.currency,	
				isnull(sum(case when bettype in (33,43) AND liveawayscore = 0 THEN isnull(stake,0)/2 
								else isnull(stake,0) end),0) as Turnover,
				isnull(sum(case when ruben=0 then isnull(actual_stake,0) else 0 end),0) as Outstanding,
				isnull(sum(case when ruben=1 then isnull(winlost,0)-isnull(actual_stake,0)+ isnull(playercomm,0) else 0 end),0) as Winlost,
				isnull(sum(case when StatusID=111/*status in ('DRAW')*/ then isnull(stake,0) else 0 end),0) as DrawGame											
		from #MemberInfo m with (nolock)	
		JOIN Product sp with (nolock) on 1=1			
		LEFT JOIN bodb02.dbo.bettrans14 b with (nolock) on b.CustID=m.IBCcustid		    
		where winlostdate = @winlostdate		     
			 and StatusID not in (101, 102, 103, 121)			 			 	
			and b.bettype in (select val from dbo.strSplit(sp.BettypeList,','))					   
		group by m.UserName,m.IBCCustID, m.currency,sp.ProductID,              
                m.AffID      
   END  

--Calculate other information Deposit,withdrawal,Bonus,Adjustment

CREATE TABLE #Data1
(
	[UserName] varchar(30) primary key,	
	[AffID] int,
	[IBCCustID] int,
	[Currency] varchar(5) ,
	[Deposit] money,
	[Withdrawal] money,
	[Bonus] money,
	[Adjustment] money,
	[PSP] money,
	[Marketing] money,
	[MemWinlostFake] money,
	[MemOddsFee] money
	
)	

IF @Winlostdate < @BalanceUpDay
BEGIN
		Insert into #Data1
				(
				[UserName],				
				[AffID],
				[IBCCustID],
				[Currency],
				[Deposit],
				[Withdrawal],
				[Bonus],
				[Adjustment]
				)
		select  m.UserName,				
				m.AffID,
				m.IBCCustID,
				m.currency,	
				sum( case when bettype=107 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Deposit,
				-sum( case when bettype in (108,109) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Withdrawal,
				sum( case when bettype=110 then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Bonus, 
				sum( case when bettype in (101, 102, 103, 104, 105, 111) then isnull(Credit,0)-isnull(Debit,0) else 0 end) as Adjustment 
     
			from #MemberInfo m with (nolock)
				 inner join DB06.bodb_Archive.dbo.transfer_bk b with (nolock) on b.custid=m.IBCCustID and b.recommend= m.recommend				
			where winlostdate=@Winlostdate				 
				and bettype in(107,110,108,109,101, 102, 103, 104, 105, 111)
			 group by m.UserName,m.IBCCustID, m.currency,m.AffID 
END
ELSE
BEGIN

		Insert into #Data1
				(
				[UserName],				
				[AffID],
				[IBCCustID],
				[Currency],
				[Deposit],
				[Withdrawal],
				[Bonus],
				[Adjustment]
				)
		select  m.UserName,				
				m.AffID,
				m.IBCCustID,
				m.currency,	
				sum( case when bettype=107 then isnull(Winlost,0)-isnull(Actual_Stake,0) else 0 end) as Deposit,
					-sum( case when bettype in (108,109) then isnull(Winlost,0)-isnull(Actual_Stake,0) else 0 end) as Withdrawal,
					sum( case when bettype=110 then isnull(Winlost,0)-isnull(Actual_Stake,0) else 0 end) as Bonus, 
					sum( case when bettype in (101, 102, 103, 104, 105, 111) then isnull(Winlost,0)-isnull(Actual_Stake,0) else 0 end) as Adjustment
     
			from #MemberInfo m with (nolock)
				 inner join bodb02.dbo.bettrans b with (nolock) on b.custid=m.IBCCustID
			where winlostdate=@Winlostdate				
				and bettype in(107,110,108,109,101, 102, 103, 104, 105, 111)
			 group by m.UserName,m.IBCCustID, m.currency,m.AffID 
	
END

declare @SportsBookID int
select @SportsBookID=dbo.Aff_GetProductID('SportsBook')

BEGIN TRANSACTION  
BEGIN TRY  
 DELETE FROM MemberDaily WHERE winlostdate = @winlostdate and AffID=@AffID	
 INSERT INTO [MemberDaily]
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
           ,[MemOddsFee]) 
	Select 
			d.[UserName]
           ,@winlostdate
           ,d.[ProductID]
           ,d.[AffID]
           ,d.[IBCCustID]
           ,d.[Currency]
           ,ai.[Currency]
           ,(case when ai.currency='USD' then e.USD
					  when ai.currency='EUR' then e.EUR
					  when ai.currency='CNY' then e.CNY
					  when ai.currency='UUS' then e.UUS	 
					  else e.UUS end) AffExRate
           ,@SystemCurrency
           ,(case when @SystemCurrency='USD' then e.USD
					  when @SystemCurrency='EUR' then e.EUR
					  when @SystemCurrency='CNY' then e.CNY
					  when @SystemCurrency='UUS' then e.UUS	 
					  else e.UUS end) SysExRate
           ,0 as [Deposit]
           ,0 as [Withdrawal]
           ,0 as [Bonus]
           ,0 as [Adjustment]
           ,d.[Turnover]
           ,d.[Outstanding]
           ,d.[Winlost]
           ,d.[DrawGame]
           ,0 as [PSP]
           ,0 as [Marketing]
           ,0 as [MemWinlostFake]
           ,0 as [MemOddsFee]
	From #Data d with (nolock)
		LEFT JOIN @AffExchange e on e.currency=d.currency
		LEFT JOIN AffInfo ai with (nolock) on ai.AffID=d.AffID

	update md
	set		md.[Deposit]=d.Deposit
           ,md.[Withdrawal]=d.Withdrawal
           ,md.[Bonus]=d.Bonus
           ,md.[Adjustment]=d.Adjustment
		   ,md.PSP=(abs(d.Deposit) * isnull(e.DepositPercent,0) + abs(d.Withdrawal) * isnull(e.WithdrawalPercent,0))
		   ,md.Marketing=abs(md.Winlost) * isnull(dbo.Aff_GetDeductionPercent(md.AffID,@SportsBookID,'Marketing',@WinlostDate),0)
		   ,md.[MemOddsFee]=abs(md.Winlost) * isnull(dbo.Aff_GetDeductionPercent(md.AffID,@SportsBookID,'Odds Fee',@WinlostDate),0)
		   ,md.[MemWinlostFake]= -(-Winlost
      - ((abs(d.Deposit) * e.DepositPercent + abs(d.Withdrawal) * e.WithdrawalPercent))* isnull(dbo.Aff_GetDeductionPercent(md.AffID,@SportsBookID,'PSP',@WinlostDate),0)
      -  abs(md.Winlost) * isnull(dbo.Aff_GetDeductionPercent(md.AffID,@SportsBookID,'Marketing',@WinlostDate),0)
      - abs(md.Winlost) * isnull(dbo.Aff_GetDeductionPercent(md.AffID,@SportsBookID,'Odds Fee',@WinlostDate),0)
      )
	from MemberDaily md with (rowlock,updlock)
		inner join #Data1 d with (nolock) on d.username=md.username
		LEFT JOIN @AffExchange e on e.currency=d.currency
	where md.Winlostdate=@Winlostdate and md.ProductID=@SportsBookID
	
	INSERT INTO [MemberDaily]
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
           ,[MemOddsFee]) 
     Select 
			d.[UserName]
           ,@winlostdate
           ,@SportsBookID
           ,d.[AffID]
           ,d.[IBCCustID]
           ,d.[Currency]
           ,ai.[Currency]
           ,(case when ai.currency='USD' then e.USD
					  when ai.currency='EUR' then e.EUR
					  when ai.currency='CNY' then e.CNY
					  when ai.currency='UUS' then e.UUS	 
					  else e.UUS end) AffExRate
           ,@SystemCurrency
           ,(case when @SystemCurrency='USD' then e.USD
					  when @SystemCurrency='EUR' then e.EUR
					  when @SystemCurrency='CNY' then e.CNY
					  when @SystemCurrency='UUS' then e.UUS	 
					  else e.UUS end) SysExRate
           ,d.[Deposit]
           ,d.[Withdrawal]
           ,d.[Bonus]
           ,d.[Adjustment]
           ,0 as [Turnover]
           ,0 as [Outstanding]
           ,0 as [Winlost]
           ,0 as [DrawGame]
           ,(abs(d.Deposit) * isnull(e.DepositPercent,0) + abs(d.Withdrawal) * isnull(e.WithdrawalPercent,0)) as [PSP]
           ,0 as [Marketing]
           ,0 as [MemWinlostFake]
           ,0 as [MemOddsFee]
	From #Data1 d with (nolock)
		LEFT JOIN @AffExchange e on e.currency=d.currency
		LEFT JOIN AffInfo ai with (nolock) on ai.AffID=d.AffID
     where d.username not in (
			select distinct username from MemberDaily (nolock) where winlostdate=@WinlostDate and ProductID=@SportsBookID
		)

	--Update table AffDaily.

	DELETE FROM AffDaily WHERE winlostdate = @winlostdate and AffID=@AffID	
	INSERT INTO [AffDaily]
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
           ,[MemOddsFee])
	
	select  d.AffID,      
			d.Currency,       
			d.Winlostdate,       
			d.ProductID as ProductID,      
			d.AffCurrency,       
			d.AffExRate,
			d.SysCurrency,
			d.SysExRate,
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
		where d.WinlostDate =@winlostdate and AffID=@AffID	
		GROUP BY d.AffID,      
			d.Currency,       
			d.Winlostdate,       
			d.ProductID,      
			d.AffCurrency,       
			d.AffExRate,
			d.SysCurrency,
			d.SysExRate   

		update AffDaily with (rowlock,updlock)

		set [MemMarketing]= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',Winlostdate),0),
			MemOddsFee= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',Winlostdate),0),  
			HouseNetWinLost=HouseWinLost
							- isnull(MemBonus,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',Winlostdate),0)   
							-isnull(MemAdjustment,0)
							-isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',Winlostdate),0)
							- abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',Winlostdate),0)
							- abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',Winlostdate),0),
			MemWinlostFake=-(-isnull(MemWinlost,0)
							 -isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',Winlostdate),0)		
							 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',Winlostdate),0)		
							 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',Winlostdate),0)
							)
		where WinlostDate =@winlostdate and AffID=@AffID	
	
	--Update Table AffDailySummary
	DELETE FROM AffDailySummary 
	WHERE WinlostDate = @winlostdate and AffID=@AffID	
	INSERT INTO [AffDailySummary]
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
           ,[MemWinlostFake_aff])

			select   [AffID]
           ,[Winlostdate]
           ,[ProductID]
		   ,[AffCurrency]
           ,[SysCurrency]
           ,sum([MemDeposit]* SysExRate) as MemDeposit
           ,sum([MemWithdrawal]*SysExRate) as MemWithdrawal
           ,sum([MemTurnover]*SysExRate) as MemTurnover
           ,sum([MemBonus]*SysExRate) as MemBonus
           ,sum([MemAdjustment] * SysExRate) as MemAdjustment
		   ,0 as MemMarketing	
           ,sum([MemPSP] * SysExRate) as MemPSP
           ,sum([MemWinlost] * SysExRate) as MemWinlost
           ,sum([AffWinlost] * SysExRate) as AffWinlost
           ,sum([HouseWinlost] * SysExRate) as HouseWinlost
           ,sum([AffNetWinlost]*SysExRate) as AffNetWinlost
           ,sum([HouseNetWinlost]*SysExRate) as HouseNetWinlost
           ,0 as MemOddsFee          
		   ,sum([MemDeposit]* AffExRate) as MemDeposit_Aff
           ,sum([MemWithdrawal]*AffExRate) as MemWithdrawal_Aff
           ,sum([MemTurnover]*AffExRate) as MemTurnover_Aff
           ,sum([MemBonus]*AffExRate) as MemBonus_Aff
           ,sum([MemAdjustment] * AffExRate) as MemAdjustment_Aff
		   ,0 as MemMarketing_Aff	
           ,sum([MemPSP] * AffExRate) as MemPSP_Aff
           ,sum([MemWinlost] * AffExRate) as MemWinlost_Aff
           ,sum([AffWinlost] * AffExRate) as AffWinlost_Aff
           ,sum([HouseWinlost] * AffExRate) as HouseWinlost_Aff    
		   ,sum([AffNetWinlost]*AffExRate) as AffNetWinlost
           ,sum([HouseNetWinlost]*AffExRate) as HouseNetWinlost     
           ,0 as MemOddsFee_Aff
           ,0 as MemWinlostFake_Aff

		from AffDaily(nolock)
		where WinlostDate = @winlostdate and AffID=@AffID	
		group by AffID,Winlostdate,ProductID,[AffCurrency],[SysCurrency]

	update AffDailySummary with (rowlock,updlock)
	set MemOddsFee=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate),
    MemMarketing=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate),         
     HouseNetWinlost=(
						-MemWinlost
                        -MemBonus * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)
						-MemAdjustment
						-MemPSP * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)
						- abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)
					 ),
	MemOddsFee_aff=abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate),
    MemMarketing_aff=abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate),         
    MemWinlostFake_aff=  -(-MemWinlost_aff
                     - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)
					 - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)
					 - MemPSP_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)),
	HouseNetWinlost_aff=(
						-MemWinlost_aff
                        -MemBonus_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)
						-MemAdjustment_aff
						-MemPSP_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)
						- abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)
						- abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)
					 )   		
     
  where WinlostDate = @winlostdate and AffID=@AffID	

	--if currrent_timestamp  > @winlostdate -1 and @winlostdate is last day of month

	Declare @FirstDay smalldatetime,@LastDay smalldatetime
	 Select @FirstDay = cast(cast(year(@winlostdate) as varchar(5)) + '-' + cast(month(@winlostdate) as varchar(5)) + '-' +'1' as smalldatetime)
	--Get last day of inputted month
	Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))
 /*update last MemWinlostFake of last transaction date for each acount
	For example: Affiliate 1 : last day =28/11
				Affiliate 2 : last day= 29/11
				Affiliate 3 : last day= 31/11								
 */
 
 if (datediff(d,@winlostdate,@lastday)=0 and datediff(d,@winlostdate,current_timestamp)>0 )
 begin
       
		declare @temp table(affid int,ProductID tinyint,totalWinlost money, oddsFeePercent float,marketingPercent float,PSPFeePercent float,totalPSP money,WLFake money,maxWinlostDate smalldatetime)

		insert into @temp(affid,ProductID,totalWinlost,oddsFeePercent,marketingPercent,PSPFeePercent,totalPSP,WLFake,maxWinlostDate)
		select affid,ProductID,sum(memwinlost_aff),dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',@LastDay)
			  ,dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',@LastDay),dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',@LastDay),sum(memPSP_aff),sum(memWinlostFake_aff)
			  , [dbo].[Aff_GetMaxWinlostdate] (AffID,ProductID,@winlostdate)
		from AffDailySummary ad (nolock) 
		where ad.winlostdate between @FirstDay and dateadd(d,-1,[dbo].[Aff_GetMaxWinlostdate] (AffID,ProductID,@winlostdate))
			and AffID=@AffID	
		group by ad.AffID,ProductID

		--select * from @Temp

		update d
			Set MemWinlostFake_aff=-(-(d1.totalwinlost + d.memwinlost_aff) - abs (d1.totalwinlost + d.memwinlost_aff) * (d1.oddsFeePercent + d1.marketingPercent) - (d1.totalPSP + d.memPSP_aff)*d1.PSPFeePercent)- d1.WLFake
		from AffDailySummary d with (rowlock,updlock)
			 inner join @Temp d1 on d1.affid=d.affid and d1.ProductID=d.ProductID and d1.maxWinlostDate=d.winlostdate 	
	  		 		 

	end

	COMMIT TRANSACTION   
	/*select * from @AffExchange
	Select * from MemberDaily (nolock) where WinlostDate=@WinlostDate
	Select * from AffDaily (nolock) where WinlostDate=@WinlostDate
	Select * from AffDailySummary (nolock) where WinlostDate=@WinlostDate*/
END TRY  
  
BEGIN CATCH  
 rollback transaction   
 print	ERROR_MESSAGE()
END CATCH  
  



/*
Select * from #Data (nolock)
Select * from #Data1 (nolock)
select * from #MemberInfo (nolock)
join ProductID (nolock) on 1=1
*/
drop table #Data1
drop table #Data
drop table #MemberInfo

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailySummaryForAff] TO [vnteam]