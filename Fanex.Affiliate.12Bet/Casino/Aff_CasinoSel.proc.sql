ALTER PROCEDURE [dbo].[Aff_CasinoSel]
	@Date smalldatetime
AS
/*
	Task : Get Casino Data by Date
	Author : Johnny@20120412
	DB: DB052.Affiliate_12BET
	Original: [[Aff_CasinoSel]]  
	Revisions
		-20120412@Johnny:
			+ link: http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320
*/
SET NOCOUNT ON  

select @Date = convert(varchar(10),@Date,120)

select @Date as DateImport, 
		replace(m.Username, '12bet$', '') as Username,
		ex.Currency,
		Turnover,
		Winlost,
		Bonus,
		Deposit
from MemberInfo m with (nolock)
	inner join Memberdaily md with (nolock) on md.IBCCustId = m.IBCCustId
	inner join Exchange_Current ex with (nolock) on md.Currency = ex.ExchangeID
where md.WinlostDate = @Date and md.SportType = 3
order by m.Username

GO
GRANT EXECUTE ON [dbo].[Aff_CasinoSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CasinoSel] TO [VNTeam]
  