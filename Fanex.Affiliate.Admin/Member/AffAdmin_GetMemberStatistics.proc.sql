ALTER Procedure [dbo].[AffAdmin_GetMemberStatistics]  
	@UserId int = 0,
	@AffType tinyint = 0,  
	@DepositAll money= 0 Output,  
	@DepositMonth money= 0 Output,  
	@PSPFeeAll money= 0 Output,  
	@PSPFeeMonth money= 0 Output,  
	@WinlostAll money= 0 Output,  
	@WinlostMonth money= 0 Output,  
	@BonusAll money= 0 Output,  
	@BonusMonth money= 0 Output,  
	@AdjustmentAll money= 0 Output,  
	@AdjustmentMonth money= 0 Output,  
	@NetWinlostAll money= 0 Output,  
	@NetWinlostMonth money= 0 Output,
	@TurnoverAll money = 0 Output,
	@TurnoverMonth money = 0 Output,
	@WithdrawalAll money = 0 Output,
	@WithdrawalMonth money = 0 Output,
	@TestLevel tinyint = 0
AS  
/*Created: 20131002@Johnny
Task : Gather overview statistic of member information
DB: DB052.Affiliate_AoncashUAT  
  
Revisions:  
 - 20131002@Johnny: Apply test level
 - 20131007@Johnny: Get turnover and withdrawal instead of PSP fee
Param's Explanation:  
	- @TestLevel: 0: real acc; 1: csd test; 2: QC Test
	
*/ 
SET NOCOUNT ON  
  
DECLARE @MaxWinLostDateAffComm smalldatetime,@NextMaxWinlostDate smalldatetime, @CurrentDate smalldatetime   
		
DECLARE @tmpCurrency TABLE (CurrencyID INT, ExRate FLOAT)
  
select @MaxWinLostDateAffComm=max(winlostdate) from  AffCommission with(nolock)

INSERT INTO @tmpCurrency
SELECT AttributeID, 0 AS ExRate 
FROM dbo.Aff_f_GetCurrencybyUser (@userID,1)  
  
  
if @MaxWinLostDateAffComm is null  
begin  
	Select @NextMaxWinlostDate=cast ((select top(1) SValue from SystemSettings(nolock) where Type='Meta' and SName='SystemStartDate') as smalldatetime )     
end  
else     
begin  
	Select @NextMaxWinlostDate=dateadd(d, 1, @MaxWinLostDateAffComm)  
end  
    
    
select @CurrentDate= getdate()  
  
declare @TblStatistics as table(deposit money, winlost money, bonus money, psp money, Adjustment money, Turnover money, Withdrawal money, WinlostDate smalldatetime)  
  
Insert into @TblStatistics(deposit, winlost, bonus, psp, Adjustment, Turnover, Withdrawal, winlostdate)    
select   
	sum(isnull(MemberDeposit, 0)) as deposit,  
	sum((isnull(MemberWinlost, 0))) as winlost,  
	sum(isnull(MemberBonus, 0)) as bonus,  
	sum(isnull(MemberPSP, 0)) as psp,  
	sum(isnull(MemberAdjustment, 0)) as Adjustment,  
	sum(isnull(MemberTurnover, 0)) as Turnover,  
	sum(isnull(MemberWithdrawal, 0)) as Withdrawal,
	@MaxWinLostDateAffComm as winlostdate    
from AffCommission ac with (nolock)  
	inner join AffInfo ai with (nolock) on ac.AffId = ai.AffId  
	INNER JOIN @tmpCurrency t ON ai.Currency = t.CurrencyID
where  (@AffType = 0 or ai.AffType = @AffType) 
		and ProductID > 0 
		and winlostdate < @NextMaxWinlostDate
		And isnull(ai.Level, 0) <= @TestLevel
union all  
select   
	sum(isnull(MemDeposit, 0)*SysExRate) as deposit,  
	sum((isnull(MemWinlost, 0))*SysExRate) as winlost,  
	sum(isnull(MemBonus, 0)*SysExRate) as bonus,  
	sum(isnull(MemPSP, 0)*SysExRate) as psp,  
	sum(isnull(MemAdjustment, 0)*SysExRate) as Adjustment,  
	sum(isnull(MemTurnover, 0)*SysExRate) as Turnover,  
	sum(isnull(MemWithdrawal, 0)*SysExRate) as Withdrawal,  
	dateadd(mm, DATEDIFF(m,0,md.Winlostdate), 0) as winlostdate  
from AffDaily md with (nolock)  
	inner join AffInfo ai with(nolock) on md.AffId = ai.AffId   
	INNER JOIN @tmpCurrency t ON ai.Currency = t.CurrencyID
where (@AffType=0 or ai.AffType = @AffType) 
		and Winlostdate between @NextMaxWinlostDate  and @CurrentDate 
		And isnull(ai.Level, 0) <= @TestLevel
group by dateadd(mm, DATEDIFF(m,0,md.winlostdate), 0)  
                 
SELECT    
	@DepositAll =  SUM(isnull(Deposit,0)),  
	@WinlostAll = SUM(isnull(Winlost,0)),  
	@BonusAll = SUM(isnull(Bonus,0)),  
	@PSPFeeAll = SUM(isnull(PSP,0)),  
	@AdjustmentAll = SUM(isnull(Adjustment,0)),  
	@TurnoverAll = SUM(isnull(Turnover,0)),  
	@DepositMonth =SUM(case when datediff(m, @CurrentDate, winlostdate)=0  then isnull(Deposit,0) else 0 end),  
	@WinlostMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Winlost,0) else 0 end),  
	@BonusMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Bonus,0) else 0 end),  
	@PSPFeeMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(PSP,0) else 0 end),  
	@AdjustmentMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Adjustment,0) else 0 end),
	@TurnoverMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Turnover,0) else 0 end)   
FROM @TblStatistics       
   
   
 SELECT @NetWinlostAll = isnull(@WinlostAll,0) + isnull(@BonusAll,0) + isnull(@AdjustmentAll,0),  
        @NetWinlostMonth = isnull(@WinlostMonth,0) + isnull(@BonusMonth,0) + isnull(@AdjustmentMonth,0)  
  
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetMemberStatistics] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GetMemberStatistics] TO [vnteam]