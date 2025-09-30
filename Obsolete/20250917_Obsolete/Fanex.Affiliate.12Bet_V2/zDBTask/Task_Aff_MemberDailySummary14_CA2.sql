ALTER PROCEDURE [dbo].[Task_Aff_MemberDailySummary14_CA2]
	@Winlostdate datetime
AS
/*
	Created: 20090701@VietHoang
	Task : Summary data from 12BET Affiliates members
	DB: DB052.Affiliate_12BET

	Revisions:				
		             
	Param's Explanation:
	• @winlostdate: The date need to summary
*/
SET NOCOUNT ON
SELECT @WinlostDate = Convert(varchar(10),@WinlostDate,120)
DECLARE @Data TABLE(IBCCustID int PRIMARY KEY, DepositCustID int, currency int,
			OpeningBalance money default(0), Deposit money, Withdrawal money, Aff2MemTransfer money,
			Bonus money, Adjustment money, Turnover money, Outstanding money, Winlost money, ClosingBalance money,
			AffExRate float, MemberExRate float, Transfer3rd money, DrawGame money, PSP money default(0), Marketing money default(0))

INSERT INTO @Data (IBCCustID, DepositCustID, currency, MemberExRate)
SELECT IBCCustID, DepositCustID, currency, (select top(1) actualrate from bodb02.dbo.bettrans14 (nolock) where winlostdate=@winlostdate and currency=m.currency)      
FROM MemberInfo m

update d 
set AffExRate = convert(float,e.actualrate2) 
from @Data d 
	inner join Exchange e on datediff(month,@winlostdate,e.updatedtime) = 0		
		and e.Exchangeid = d.currency 

Update @Data set OpeningBalance = (select isnull(sum(winlost-actual_stake + isnull(playercomm,0)),0)
								    from bodb02.dbo.bettrans b with (nolock)
									where b.custid = d.IBCCustID and winlostdate < @winlostdate)
from @Data d	


Update d set
	Deposit = isnull(b1.Deposit,0),
	Aff2MemTransfer = isnull(b1.Aff2MemTransfer,0),
	Withdrawal = isnull(b1.Withdrawal,0),
	Bonus = isnull(b1.Bonus,0),
	Adjustment = isnull(b1.Adjustment,0),
	Turnover = isnull(b1.Turnover,0),
	Outstanding = isnull(b1.Outstanding,0),
	Winlost = isnull(b1.Winlost,0),	
	Transfer3rd = isnull(b1.Transfer3rd,0),
	DrawGame = isnull(b1.DrawGame,0)
from @Data d		
	left join (
		select b.custid,
				isnull(sum(case bettype when 107 then winlost-actual_stake else 0 end),0) as Deposit,
				isnull(sum(case bettype when 106 then winlost-actual_stake else 0 end),0) as Aff2MemTransfer,				
				-isnull(sum(case when bettype in (108,109) then winlost-actual_stake else 0 end),0) as Withdrawal,
				isnull(sum(case bettype when 110 then winlost-actual_stake else 0 end),0) as Bonus,
				isnull(sum(case when bettype in (101, 102, 103, 104, 105, 111) then winlost-actual_stake else 0 end),0) as Adjustment,
				isnull(sum(case bettype when 115 then winlost-actual_stake else 0 end),0) as Transfer3rd,
				isnull(sum(case when bettype < 99 and status not in ('VOID', 'REJECT', 'REFUND') then stake else 0 end),0) as Turnover,
				isnull(sum(case when bettype < 99 and status in ('DRAW') then stake else 0 end),0) as DrawGame,
				isnull(sum(case when bettype < 99 and ruben=0 then actual_stake else 0 end),0) as Outstanding,
				isnull(sum(case when bettype < 99 and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) as Winlost				
		from 
			(select winlostdate,custid, currency, winlost, awinlost, mwinlost, actual_stake, stake,ruben, bettype, playercomm, status from bodb02.dbo.bettrans with(nolock)
			 union all
			 select winlostdate,custid, currency, winlost, awinlost, mwinlost, actual_stake,stake,ruben, bettype, playercomm, status from bodb02.dbo.bettrans14 with(nolock)
			 ) b
			INNER JOIN MemberInfo m on b.custid = m.IBCCustID
		where winlostdate = @winlostdate
		group by b.custid
	) b1 on d.IBCCustID = b1.custid	
	

Update d set
	PSP = isnull(b1.dPSP,0)
from @Data d		
	left join (
		select m.DepositCustID,
				isnull(sum(di.chargefee),0) as dPSP
		from MemberInfo	m
			INNER JOIN [B04-05].deposit_db.dbo.deposit_depositinfo di with (nolock) on m.DepositCustID = di.custid			
		where status=2 and datediff(dd, di.ApprovedDate, @winlostdate) = 0
		group by m.DepositCustID
	) b1 on d.DepositCustID = b1.DepositCustID	


Update d set
	PSP = isnull(PSP,0) + isnull(b1.wPSP,0)
from @Data d		
	left join (
		select m.DepositCustID,
				isnull(sum(wi.chargefee),0) as wPSP
		from MemberInfo	m			
			INNER JOIN [B04-05].deposit_db.dbo.deposit_withdrawalinfo wi with (nolock) on m.DepositCustID = wi.custid		
		where status=2 and datediff(dd, wi.ApprovedDate, @winlostdate) = 0
		group by m.DepositCustID
	) b1 on d.DepositCustID = b1.DepositCustID	


--Current Day, then update all the outstanding
if convert(nvarchar(10),@winlostdate,120) = convert(nvarchar(10),current_timestamp,120)
BEGIN	
	Update @Data set Outstanding = (select isnull(sum(actual_stake),0)
									from bodb02.dbo.bettrans b with (nolock)
									where b.custid = d.IBCCustID and bettype < 99 and ruben=0)
	from @Data d
END

Update @Data set ClosingBalance = OpeningBalance + Deposit - Withdrawal + Bonus + Adjustment - Outstanding + Winlost


DELETE FROM MemberDaily WHERE winlostdate = @winlostdate

INSERT INTO MemberDaily(
	WinlostDate,
	IBCCustID,
	Currency,
	OpeningBalance,
	Deposit,
	Withdrawal,
	Aff2MemTransfer,
	Bonus,
	Adjustment,
	Turnover,
	Outstanding,
	Winlost,
	ClosingBalance,
	AffExRate,
	MemberExRate,
	Transfer3rd,
	DrawGame,
	PSP,
	Marketing
)

SELECT 
	@WinlostDate,
	IBCCustID, 	
	currency,
	OpeningBalance, 
	Deposit, 
	Withdrawal, 
	Aff2MemTransfer,
	Bonus, 
	Adjustment, 
	Turnover, 
	Outstanding, 
	Winlost, 
	ClosingBalance,
	AffExRate, 
	MemberExRate, 
	Transfer3rd, 
	DrawGame, 
	PSP, 
	Marketing
FROM @DATA

SELECT @winlostdate

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailySummary14_CA2] TO [VNTeam] 