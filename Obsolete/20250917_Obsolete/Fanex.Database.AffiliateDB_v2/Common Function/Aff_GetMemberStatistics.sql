set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER Procedure [dbo].[Aff_GetMemberStatistics]
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
	@NetWinlostMonth money= 0 Output
AS
SET NOCOUNT ON

declare @MaxWinLostDateAffComm smalldatetime,@NextMaxWinlostDate smalldatetime
declare @CurrentDate smalldatetime

select @MaxWinLostDateAffComm=max(winlostdate) from  AffCommission with(nolock)


if @MaxWinLostDateAffComm is null
begin
   Select @NextMaxWinlostDate=cast ((select top(1) SValue from SystemSettings(nolock) where Type='Meta' and SName='SystemStartDate') as smalldatetime )   
end
else   
begin
  Select @NextMaxWinlostDate=dateadd(d, 1, @MaxWinLostDateAffComm)
end
  
  
select @CurrentDate= getdate()

print @NextMaxWinlostDate
declare @TblStatistics as table(deposit money, winlost money, bonus money, psp money, Adjustment money, WinlostDate smalldatetime)

Insert into @TblStatistics(deposit, winlost, bonus, psp, Adjustment, winlostdate)		
	select 
		sum(isnull(MemberDeposit, 0)) as deposit,
		sum((isnull(MemberWinlost, 0))) as winlost,
		sum(isnull(MemberBonus, 0)) as bonus,
		sum(isnull(MemberPSP, 0)) as psp,
		sum(isnull(MemberAdjustment, 0)) as Adjustment,
		@MaxWinLostDateAffComm as winlostdate		
	from AffCommission ac with (nolock)
		inner join AffInfo ai with (nolock) on ac.AffId = ai.AffId
    where  (@AffType=0 or ai.AffType = @AffType) and ProductID>0 and winlostdate<@NextMaxWinlostDate
	union all
	select 
		sum(isnull(MemDeposit, 0)*SysExRate) as deposit,
		sum((isnull(MemWinlost, 0))*SysExRate) as winlost,
		sum(isnull(MemBonus, 0)*SysExRate) as bonus,
		sum(isnull(MemPSP, 0)*SysExRate) as psp,
		sum(isnull(MemAdjustment, 0)*SysExRate) as Adjustment,
		dateadd(mm, DATEDIFF(m,0,md.Winlostdate), 0) as winlostdate
	from AffDaily md with (nolock)
		inner join AffInfo ai with(nolock) on md.AffId = ai.AffId 
	where (@AffType=0 or ai.AffType = @AffType) and Winlostdate between @NextMaxWinlostDate  and @CurrentDate
	group by dateadd(mm, DATEDIFF(m,0,md.winlostdate), 0)
	              
	SELECT		
		@DepositAll =  SUM(isnull(Deposit,0)),
		@WinlostAll = SUM(isnull(Winlost,0)),
		@BonusAll = SUM(isnull(Bonus,0)),
		@PSPFeeAll = SUM(isnull(PSP,0)),
		@AdjustmentAll = SUM(isnull(Adjustment,0)),
        @DepositMonth =SUM(case when datediff(m, @CurrentDate, winlostdate)=0  then isnull(Deposit,0) else 0 end),
		@WinlostMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Winlost,0) else 0 end),
		@BonusMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Bonus,0) else 0 end),
		@PSPFeeMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(PSP,0) else 0 end),
		@AdjustmentMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Adjustment,0) else 0 end) 
	FROM @TblStatistics 	
	
	
	
	SELECT @NetWinlostAll = isnull(@WinlostAll,0) + isnull(@BonusAll,0) + isnull(@AdjustmentAll,0),
           @NetWinlostMonth = isnull(@WinlostMonth,0) + isnull(@BonusMonth,0) + isnull(@AdjustmentMonth,0) 
           
		   
		  
GO
GRANT EXECUTE ON [dbo].[Aff_GetMemberStatistics] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetMemberStatistics] TO [vnteam]

