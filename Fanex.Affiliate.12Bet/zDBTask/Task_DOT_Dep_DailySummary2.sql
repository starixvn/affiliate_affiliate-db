ALTER PROCEDURE [dbo].[Task_DOT_Dep_DailySummary2]
	@winlostdate datetime
AS
SET NOCOUNT ON
if @winlostdate > current_timestamp RETURN
SELECT distinct winlostdate FROM bettrans with (nolock) WHERE winlostdate = @winlostdate AND bettype < 90
IF @@ROWCOUNT = 0 RETURN

DECLARE @TempMember TABLE(custid int PRIMARY KEY) 

INSERT INTO @TempMember(custid) 
select CustID
FROM Custinfo c WITH(NOLOCK)
	inner join Affiliate_12BET.dbo.MemberInfo m with(nolock) on c.CustID = m.IbcCustID
where m.IsRemoved = 0

DECLARE @Data TABLE(custid int PRIMARY KEY, currency int,
			OpeningBalance money default(0), Deposit money, Aff2MemTransfer money,
				Withdrawal money, Bonus money, Adjustment money, Turnover money, Outstanding money, Winloss money, ClosingBalance money,
				recommend int, mrecommend int, srecommend int, awinlost money, abonus money, aExRate float, mwinlost money, Transfer3rd money, DrawGame money)--Joey add Draw column (2009-05-25)

INSERT INTO @Data (custid, currency, recommend, mrecommend, srecommend)
select distinct b.custid, currency, recommend, mrecommend, srecommend
from bettrans b with (nolock)
	INNER JOIN @TempMember m on b.custid = m.custid

Update @Data set OpeningBalance = (select isnull(sum(winlost-actual_stake + isnull(playercomm,0)),0)
									from bettrans b with (nolock)
									where b.custid = d.custid and winlostdate < @winlostdate)
from @Data d	

Update d set
	Deposit = isnull(b1.Deposit,0),
	Aff2MemTransfer = isnull(b1.Aff2MemTransfer,0),
	Withdrawal = isnull(b1.Withdrawal,0),
	Bonus = isnull(b1.Bonus,0),
	Adjustment = isnull(b1.Adjustment,0),
	Turnover = isnull(b1.Turnover,0),
	Outstanding = isnull(b1.Outstanding,0),
	Winloss = isnull(b1.Winloss,0),
	awinlost = isnull(b1.awinlost,0),
	abonus = isnull(b1.abonus,0),
	mwinlost = isnull(b1.mwinlost,0),
	Transfer3rd = isnull(b1.Transfer3rd,0),
	DrawGame = isnull(b1.DrawGame,0) -- Joey Add (2009-05-25)
from @Data d		
	left join (
		select b.custid,
				isnull(sum(case bettype when 107 then winlost-actual_stake else 0 end),0) as Deposit,
				isnull(sum(case bettype when 106 then winlost-actual_stake else 0 end),0) as Aff2MemTransfer,				
				-isnull(sum(case when bettype in (108,109) then winlost-actual_stake else 0 end),0) as Withdrawal,
				isnull(sum(case bettype when 110 then winlost-actual_stake else 0 end),0) as Bonus,
				isnull(sum(case when bettype in (101, 102, 103, 104, 105, 111) then winlost-actual_stake else 0 end),0) as Adjustment,
				isnull(sum(case bettype when 115 then winlost-actual_stake else 0 end),0) as Transfer3rd,
				isnull(sum(case when bettype < 99 and [status] not in ('VOID', 'REJECT', 'Refund') then stake else 0 end),0) as Turnover,
				isnull(sum(case when bettype < 99 and [status] = 'DRAW' then stake else 0 end),0) as DrawGame, --Joey Add (2009-05-25)
				isnull(sum(case when bettype < 99 and ruben=0 then actual_stake else 0 end),0) as Outstanding,
				isnull(sum(case when bettype < 99 and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) as Winloss,
				isnull(sum(case when bettype < 99 and ruben=1 then awinlost else 0 end),0) as awinlost,
				isnull(sum(case bettype when 110 then awinlost else 0 end),0) as abonus,
				isnull(sum(case when bettype < 99 and ruben=1 then mwinlost else 0 end),0) as mwinlost	
		from bettrans b with (nolock)		
			INNER JOIN @TempMember m on b.custid = m.custid
		where winlostdate = @winlostdate
		group by b.custid
	) b1 on d.custid = b1.custid	
	

--Current Day, then update all the outstanding
if convert(nvarchar(10),@winlostdate,120) = convert(nvarchar(10),current_timestamp,120)
BEGIN	
	Update @Data set Outstanding = (select isnull(sum(actual_stake),0)
									from bettrans b with (nolock)
									where b.custid = d.custid and bettype < 99 and ruben=0)
	from @Data d
END

Update @Data set ClosingBalance = OpeningBalance + Deposit + Aff2MemTransfer - Withdrawal + Bonus + Adjustment - Outstanding + Winloss + Transfer3rd

DELETE FROM bodb_Report.dbo.rptDepWinlost WHERE winlostdate = @winlostdate and custid in (select custid from @TempMember)

update d 
set aExRate = convert(float,e.actualrate2) 
from @Data d 
	inner join Affiliate_12BET.dbo.affiliate_Exchange e on datediff(month,@winlostdate,e.updatetime) = 0		
		and e.Exchangeid = d.currency 
	
-- for report testing (currency: UUS)
update d 
set aExRate = 1
from @Data d where currency=20		


insert into bodb_Report.dbo.rptDepWinlost (winlostdate, custid, currency, OpeningBalance, Deposit, Aff2MemTransfer, Withdrawal, Bonus, Adjustment, Transfer3rd,
	Turnover, DrawGame, Outstanding, Winloss, ClosingBalance, recommend, mrecommend, srecommend, awinlost, abonus, aExRate, mwinlost,actualrate)
select @WinlostDate, custid, currency, OpeningBalance, Deposit, Aff2MemTransfer, Withdrawal, Bonus, Adjustment, Transfer3rd,
	Turnover, DrawGame, Outstanding, Winloss, ClosingBalance,	recommend, mrecommend, srecommend, awinlost, abonus, aExRate, mwinlost,
	(select coalesce((select top(1) actualrate
	from bettrans (nolock)
   where winlostdate<=@winlostdate
	  and currency=d.currency and custid=d.custid and actualrate is not null
   order by winlostdate desc)
  ,(select top(1) actualrate from exchange (nolock) where exchangeid=d.currency))) actualrate
from @Data d

GO
GRANT VIEW DEFINITION ON [dbo].[Task_DOT_Dep_DailySummary2] TO [vnteam]