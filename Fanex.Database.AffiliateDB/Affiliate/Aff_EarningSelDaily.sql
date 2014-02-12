
GO
/****** Object:  StoredProcedure [dbo].[Aff_EarningSelDaily]    Script Date: 07/10/2013 06:06:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[Aff_EarningSelDaily]  
	@AffID int,	
	@ProductID tinyint = 0,
	@monthdate smalldatetime = null,
	@FromDate  smalldatetime = null,
	@ToDate  smalldatetime = null,
	@AffCurrency varchar(8) = 'UUS' OUTPUT
	
AS  
/*
	Created: 200900911@VinhTrinh 
	Task : [description of SP]  
	DB: DB052.Affiliate_MYM
	Revisions:  		
	      - Get data for daily report from table AffDaily instead of MemberDaily
	      - 20100520@Johnny: apply StatusID in bettrans table
	      - 20100930@Peter : Change the new formula for displayed winlost
	                   Winlost on Aff site=Winlost-Odds Management - Marketing cost -  PSP
	                   --The formula change since 1 Oct 2010--need to consider a new column MemWinlostFake on MemberDaily table if it is changed again
	                   MemWinlostFake need to be updated on TaskMemberDaily
	      - 20101228@Henry: change bettype to new range
	Param's Explanation:  
	• @custid: affliate Id  
	• @monthdate: Month date need to view.
	
	  
*/  
SET NOCOUNT ON
DECLARE @CurrDate smalldatetime

select @AffCurrency=e.CurrencyCode
from AffInfo ai (nolock)
	inner join Currency e (nolock) on e.CurrencyID=ai.Currency
where ai.AffID=@AffID

-- Exec Aff_GetPrefixByAff @AffId = @AffId, @Prefix = @Prefix OUTPUT

SET @CurrDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)
If (@monthdate is not null and (@FromDate is null or @ToDate is null))
Begin
	select @monthdate = dateadd(d, datediff(d, 0, @monthdate), 0)
	Select @fromdate = DATEADD(mm, DATEDIFF(m,0,@monthdate),0)
	Select @todate = case when @monthdate >= @CurrDate then @CurrDate else @monthdate end
End


SELECT 
	d.winlostdate, 					
	sum(d.MemDeposit_aff) as Deposit,
	sum(d.MemWithdrawal_aff) as Withdrawal,
	sum(d.MemWinlost_aff) as MemberWinlost,
	sum(d.MemWinlostFake_aff) as MemWinlostFake,
	sum(d.MemBonus_aff) as Bonus,
	sum(d.MemAdjustment_aff) as Adjustment,
	sum(d.MemTurnover_aff) as Turnover,
	sum(d.MemPSP_aff) as PSP
FROM AffDailySummary d with(nolock)			 
WHERE AffID = @AffID		
	AND d.winlostdate between @fromdate and @todate
	and (case when @ProductID = 0 then 1 when @ProductID = ProductID then 1 else 0 end) = 1
	--and (isnull(d.MemDeposit_aff,0) <>0 or isnull(MemWithdrawal_aff,0)<>0 or isnull(MemWinlost_aff,0)<>0 or isnull(MemAdjustment_Aff,0)<>0 or isnull(MemPSP_Aff,0)<>0 or isnull(MemMarketing_Aff,0)<>0 or isnull(MemDeposit,0)<>0 or isnull(MemWithdrawal,0)<>0)			
group by d.winlostdate
order by d.winlostdate



GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EarningSelDaily] TO [vnteam]