 --DB052.Affiliate_12BET
 SET NOCOUNT ON
 declare @SportsBookID int
select @SportsBookID=dbo.Aff_GetSportID('SportsBook')


 update m
 set m.AWinlost=r.awinlost,
     m.ABonus=r.abonus,
     m.Bonus=r.Bonus,
     m.Deposit=r.Deposit, 
	 m.Withdrawal=r.Withdrawal, 		
	 m.Adjustment=r.Adjustment
 from MemberDaily m with (rowlock,updlock)
     inner join DB06.bodb_report.dbo.rptDepWinlost r with(nolock) on r.CustID = m.IBCCustID	 and r.winlostdate=m.winlostdate
where m.WinlostDate < '1 Nov 2009' and m.SportType=@SportsBookID    
    