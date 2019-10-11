use Affiliate_12BET
go

/*
	Created: 20190919@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Exchange - Initialize data for new column: Gross Winloss (old products:  Gross Winloss = - Member Win loss)
*/

update dbo.rptAffCommission with (rowlock)
set GrossWinloss = -Winloss -- Gross Winloss = - Member Win loss
where ProductId > 0

update r with (rowlock)
set r.GrossWinloss = u.GrossWinloss
from dbo.rptAffCommission r
	cross apply (
		select sum(r1.GrossWinloss) as GrossWinloss
		from dbo.rptAffCommission r1 with (nolock)
		where r.MonthDate = r1.MonthDate and r.AffId = r1.AffId and r1.ProductId > 0
	) u
where r.ProductId = 0