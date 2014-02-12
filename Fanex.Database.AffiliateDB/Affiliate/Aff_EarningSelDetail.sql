ALTER PROCEDURE [dbo].[Aff_EarningSelDetail]
	@AffId int = 0,
	@ProductID tinyint = 0,
	@MonthDate smalldatetime,
	@AffCurrency varchar(8) = 'UUS' OUTPUT
AS
/*
	Created: 200900911@VinhTrinh
	Task : [description of SP]  
	DB: DB052.Affiliate_ZZun
	Revisions:  		
	      - addition Prefix info
	Param's Explanation:  
	• @AffId affliate Id  
	• @MonthDate Month date need to view.  
*/  
SET NOCOUNT ON

select @MonthDate = dateadd(d, datediff(d, 0, @MonthDate), 0)

-- Exec Aff_GetPrefixByAff @AffId = @AffId, @Prefix = @Prefix OUTPUT

select @AffCurrency=e.CurrencyCode
from AffInfo ai (nolock)
	inner join Currency e (nolock) on e.CurrencyID=ai.Currency
where ai.AffID=@AffID



SELECT 
		m.UserName,		
		isnull(Sum(d.Winlost * AffExRate), 0) as winlost,
		isnull(Sum(d.Deposit * AffExRate), 0) as Deposit,
		isnull(Sum(d.Withdrawal * AffExRate), 0) as Withdrawal,
		isnull(Sum(d.Bonus * AffExRate), 0) as Bonus,
		isnull(Sum(d.Turnover * AffExRate), 0) as Turnover,
		isnull(Sum(d.Adjustment * AffExRate), 0) as Adjustment,
		isnull(Sum(d.PSP * AffExRate), 0) as PSP
	FROM MemberDaily d with(nolock)
		inner join MemberInfo m with (nolock) on m.UserName = d.UserName
	WHERE d.AffID = @AffID		
		AND d.winlostdate = @MonthDate
		and (case when @ProductID = 0 then 1 when @ProductID = ProductID then 1 else 0 end) = 1		
	GROUP BY  m.UserName
																
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbAdminNet]