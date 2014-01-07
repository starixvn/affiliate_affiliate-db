ALTER Procedure [dbo].[Task_Aff_MemberDailyTransactionImportData]	
	@AdminID int,	
	@XmlData XML,	
	@WinlostDate smalldatetime,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*
	Task : Import member daily (deposit, withdrawal, Bonus,....) from xml into table MemberDaily
	Author : Joseph@20130114
	DB: DB052.Affiliate_MYM
	Original: [Aff_MemberDailyImportData]
	Revisions: 		
		- Johnny@20130402: Fix the way import transfer transaction
		- Peter@20131028 : Add more DB columns https://redmine.nexcel.vn/issues/5280
*/
BEGIN  
SET NOCOUNT ON 

-- check data is calculated for this month?

if exists(select top(1) 1 from AffCommission (nolock) where DATEDIFF(m,@WinlostDate,Winlostdate)=0)
   return

Declare @SportsBookID tinyint, @SystemCurrency smallint--Deposit, withdraw,... is assigned to sportbook

select @SportsBookID = dbo.Aff_GetSportID('SportsBook') 
Exec Aff_GetSystemCurrency @SystemCurrency = @SystemCurrency output

DECLARE @MemberTrans table(UserName varchar(30), AffID int, [Action] varchar(30), WinlostDate smalldatetime)
--Import new Data here
DECLARE @TempTrans TABLE(
	UserName varchar(30),
	WinlostDate smalldatetime,
	Currency varchar(5),
	Deposit money,
	Withdrawal money, 
	Bonus money,
	Adjustment money,
	AffTransfer money,
	Transfer3rd money);


INSERT INTO @TempTrans --Convert xml to table
SELECT				
		[Table].[Column].value('./@username', 'varchar(30)') as [UserName],		
		[Table].[Column].value('./@winlostdate', 'smalldatetime') as [WinlostDate],
		[Table].[Column].value('./@currency', 'varchar(5)') as [Currency],
		[Table].[Column].value('./@deposit', 'money') as [Deposit],
		[Table].[Column].value('./@withdrawal', 'money') as [Withdrawal],
		[Table].[Column].value('./@bonus', 'money') as [Bonus],
		[Table].[Column].value('./@adjustment', 'money') as [Adjustment],
		[Table].[Column].value('./@afftransfer', 'money') as [AffTransfer],
		[Table].[Column].value('./@transfer3rd', 'money') as [Transfer3rd]
	FROM @XmlData.nodes('/root/trans') as [Table]([Column]);

;WITH TData AS
(
	SELECT temp.*
		, mi.AffID
		, mi.Currency
		, ai.Currency AS AffCurrency
		, mi.IsRemoved
	FROM @TempTrans AS temp
	INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON temp.UserName = mi.UserName
	INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON tmp.AffId = ai.AffId
	WHERE temp.WinlostDate=@WinlostDate 
		AND LEN(temp.UserName) > 0
		AND LEN(temp.Currency) > 0
		AND mi.IsRemoved=0
)
MERGE INTO dbo.MemberDaily AS md
USING TData AS tmp 
	ON tmp.UserName = md.UserName AND md.WinlostDate = tmp.WinlostDate

WHEN MATCHED AND md.ProductID=@SportsBookID  THEN
	UPDATE
	SET [Deposit] = tmp.Deposit,
		[Withdrawal] = tmp.Withdrawal,
		[Bonus] = tmp.Bonus,
		[Adjustment] = tmp.Adjustment,     
		[AffTransfer] = tmp.AffTransfer,     
		[Transfer3rd] = tmp.Transfer3rd   

WHEN NOT MATCHED BY TARGET THEN
	INSERT([UserName]
			,[WinlostDate]
			,[ProductID]       
			,[AffID]       
			,[Currency] 
			,[AffCurrency]   
			,[AffExRate]
			,[SysCurrency]
			,[SysExrate]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]			
			,AffTransfer
			,Transfer3rd
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[DrawGame]
			,[PSP]
			,[Marketing]
			,[MemWinlostFake]
			,[MemOddsFee]
			,[MemPLayTechFee]
			,[BetCount]
			,[PlayerComm]
			,[TurnoverNoDraw]
			,[BetCountNoDraw]
			,[TurnoverDraw]
		)
	VALUES(tmp.UserName, 
			tmp.WinlostDate, 
			@SportsBookID,--is not bet transaction -> productid = sportbook ID
			tmp.AffID,
			tmp.Currency, 
			tmp.AffCurrency,   
			dbo.Aff_GetExchangeRate(tmp.Currency, tmp.AffCurrency, @WinlostDate),
			@SystemCurrency,
			dbo.Aff_GetExchangeRate(tmp.Currency, @SystemCurrency, @WinlostDate), 
			tmp.Deposit,
			tmp.Withdrawal,
			tmp.Bonus,	
			tmp.Adjustment,			
			tmp.AffTransfer,
			tmp.Transfer3rd
			,0 --Turnover
			,0 -- [Outstanding]
			,0 -- [Winlost]
			,0 -- [DrawGame]
			,0 -- [PSP]
			,0 -- [Marketing]
			,0 -- [MemWinlostFake]
			,0 -- [MemOddsFee]
			,0 -- [MemPLayTechFee]
			,0 -- [BetCount]
			,0 -- [PlayerComm]
			,0 -- [TurnoverNoDraw]
			,0 -- [BetCountNoDraw]
			,0 -- [TurnoverDraw])
		)
OUTPUT $action, Inserted.AffID, Inserted.UserName,  Inserted.WinlostDate
INTO @MemberTrans([Action], AffID, UserName, WinlostDate);

--Update MemberDaily PSP, Marketting fee,...
Update m
set PSP = ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent) * isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'PSP',@WinlostDate),0)  ),
	Marketing = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Marketing',@WinlostDate),0),
	MemOddsFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Odds Fee',@WinlostDate),0),
	MemPLayTechFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'PlayTech Royalties', @WinlostDate),0),
	MemWinlostFake = -(-Winlost  
						   - ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent))* isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'PSP',@WinlostDate),0)  
						   -  abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Marketing', @WinlostDate),0)  
						   - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Odds Fee', @WinlostDate),0)  
						   - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'PlayTech Royalties', @WinlostDate),0)  
						)
FROM dbo.MemberDaily AS m WITH (NOLOCK)
INNER JOIN @MemberTrans AS trans 
	ON (m.UserName=trans.UserName AND m.AffID=trans.AffID AND m.WinlostDate=trans.WinlostDate)
INNER JOIN Exchange AS e (nolock) on m.Currency = e.ExchangeId
WHERE m.WinlostDate=@WinlostDate


------------Update others field MemberDaily, insert data for AffDaily, AffDailySummary table

--Delete data and re-import AffDaily, AffDailySummary
DELETE FROM AffDaily
WHERE WinlostDate = @WinlostDate

DELETE FROM [AffDailySummary]
WHERE WinlostDate = @WinlostDate
		
	
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
        ,[MemTurnoverDraw] 
		)

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
		,SUM( case when Turnover>0 then 1 else 0 end) as ActivePlayer
		,SUM(TurnoverNoDraw)
        ,SUM(BetCountNoDraw)
        ,SUM(TurnoverDraw)   
from MemberDaily(nolock) as m
where m.WinlostDate = @WinlostDate
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
where WinlostDate = @winlostdate

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
	,[MemAffTransfer]
	,[MemTransfer3rd]
	,[MemBetCount]
	,[MemPlayerComm]
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

	,Sum([MemAffTransfer] * SysExRate)
	,Sum([MemTransfer3rd] * SysExRate)
	,Sum([MemBetCount])
	,Sum([MemPlayerComm] * SysExRate)

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

	,Sum([MemAffTransfer] * AffExRate)
	,Sum([MemTransfer3rd] * AffExRate)	
	,Sum([MemPlayerComm] * AffExRate)
	,SUM([MemTurnoverNoDraw] * SysExRate) as MemTurnoverNoDraw
    ,SUM([MemBetCountNoDraw])
    ,SUM([MemTurnoverNoDraw] * AffExRate) as  MemTurnoverNoDraw_aff
    ,SUM([MemTurnoverDraw] * SysExRate) as MemTurnoverDraw
    ,SUM([MemTurnoverDraw] * AffExRate) as MemTurnoverDraw_aff



from AffDaily(nolock)  
where WinlostDate = @winlostdate
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



where WinlostDate = @winlostdate



-----------Update MemwinlostFake for last date (forex winlost for previous date) of each account
declare @temp table(affid int,ProductID int,totalWinlost money, oddsFeePercent float,marketingPercent float,PSPPercent float, PlaytechPercent float,WLFake money,totalPSP money,maxWinlostDate smalldatetime,previousMaxWinlostDate smalldatetime,firstday smallDateTime)  
  
insert into @temp(Affid,maxWinlostDate,ProductID)  
select affid,max(winlostdate),ProductID  
from AffDailySummary (nolock)  
where datediff(m,@winlostdate,WinlostDate)=0--  and ProductID = @SportsBookID      
group by affid,ProductID,month(winlostdate),year(winlostdate)  
  
update t  
set t.previousMaxWinlostDate=isnull(  
          (select max(winlostdate)   
           from AffDailySummary (nolock)   
            where ProductID=t.ProductID and winlostdate<t.maxWinlostDate   
            and datediff(m,winlostdate,t.maxWinlostDate)=0  
            and affid=t.affid  
            ) ,t.maxWinlostDate)  
	,t.firstday=[dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate)      
	,t.oddsFeePercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'Odds Fee',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
	,t.marketingPercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'Marketing',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
	,t.PSPPercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'PSP',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
	,t.PlaytechPercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'PlayTech Royalties',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
from @temp t  
  
--reupdate WinlostFake of previous MaxWinlostDate for AffDailySummary    
update ad    
set ad.MemWinlostFake=-(-isnull(ad.MemWinlost,0)  
      -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'Odds Fee',ad.Winlostdate),0)  
      -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'Marketing',ad.Winlostdate),0)          
      -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'PlayTech Royalties',ad.Winlostdate),0)          
      -isnull(ad.MemPSP,0) *  isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'PSP',ad.Winlostdate),0)          
     )  
from AffDailySummary ad with (rowlock,updlock)        
	inner join @temp t on t.affid=ad.AffID and t.previousMaxWinlostDate=ad.WinlostDate and t.ProductID=ad.ProductID  
  
--don so tien winlostFake tat ca vao ngay cuoi cung cua thang nay 
update d    
set d.totalWinlost=isnull(c.totalwinlost,0)  
   ,d.WLFake=isnull(c.memWinlostFake,0)  
   ,d.totalPSP=isnull(c.memPSP,0)   
from @temp d  
	left join  
		( select t.affid,t.ProductID,sum(ad.memwinlost) totalwinlost,sum(ad.memWinlostFake) memWinlostFake, sum(ad.MemPSP) as memPSP  
		from AffDailySummary ad (nolock)   
			inner join @temp t on t.AffID=ad.AffID and t.ProductID=ad.ProductID  
		where ad.WinlostDate between t.firstday and  t.previousMaxWinlostDate  
		--and ad.ProductID = @SportsBookID  
		group by t.Affid,t.ProductID     
		) c on c.AffID=d.AffID  and c.ProductID=d.ProductID   
  
--Member Winlost - All Fee - Winlost fake from first date of month to yesterday
update d  
Set MemWinlostFake=-(-(d1.totalwinlost + d.memwinlost) - abs (d1.totalwinlost + d.memwinlost) * (d1.oddsFeePercent+d1.marketingPercent+d1.PlaytechPercent)-(d1.totalPSP+d.MemPSP)* d1.PSPPercent)- d1.WLFake  
from AffDailySummary d with (rowlock,updlock)  
	inner join @temp d1 on d1.affid=d.affid and  d1.maxWinlostDate=d.winlostdate and d1.ProductID=d.ProductID       
where d1.previousMaxWinlostDate < d1.maxWinlostDate  
	--and d.ProductID = @SportsBookID
  

END