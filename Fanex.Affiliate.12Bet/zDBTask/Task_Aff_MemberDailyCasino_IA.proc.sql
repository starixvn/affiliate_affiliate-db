ALTER PROCEDURE [dbo].[Task_Aff_MemberDailyCasino_IA]
	@AdminID int,
	@WinlostDate smalldatetime,
	@XmlData XML,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(500) = '' OUTPUT
AS
/*
	Created: 20090701@Peter
	Task : Summary data from 12BET Affiliates Income Access members, This service will occurs every 2 hours and every day at 00:00
	DB: DB06.bodb02

	Revisions:			
		20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])		 

	Param's Explanation:
	• @winlostdate: The data need to summary
*/

-- HARD CODE: not cal before 1st June 2011 (Start time to support Income Access Platform)
-- HARD CODE: not cal before 1st Nov 2011 (Exclude Number Game from Sportsbook commission)
SET NOCOUNT ON


--Get Exchange Rate
DECLARE @TempTrans TABLE(DateImport smalldatetime, UserName nvarchar(30), Currency nvarchar(50), Turnover money, Winlost money, Deposit money, Bonus money)--Convert XML to data table
DECLARE @AffExchange table(ExchangeID int primary key,ActualRate float,ActualRate2 float, DepositPercent float)
DECLARE @CasinoId int, @DepositPercent float, @MarketingPercent float, @OddsFeePercent float

SELECT @DepositPercent=0, @MarketingPercent = 0, @OddsFeePercent = 0 --@DepositPercent=0.06, @WithdrawalPercent=0.03
SELECT @CasinoId = 3

INSERT INTO @AffExchange(ExchangeID,ActualRate,ActualRate2,DepositPercent)
SELECT exchangeid, actualrate, eur, @DepositPercent
FROM ExchangeDailyOanda with(nolock)
WHERE exchangedate = @Winlostdate

--Conver XML data to table (SQL bulk insert)
insert into @TempTrans--Convert xml to table
select 	 
	DateImport,
	Username,
	Currency,
	Turnover,
	Winlost,
	Deposit,
	Bonus
from
	(Select
		[Table].[Column].value('./@date', 'smalldatetime') as [DateImport],
		[Table].[Column].value('./@username', 'varchar(100)') as [Username],
		[Table].[Column].value('./@currency', 'nvarchar(50)') as [Currency],
		[Table].[Column].value('./@turnover', 'float') as [Turnover],
		[Table].[Column].value('./@winlost', 'float') as [Winlost],
		[Table].[Column].value('./@deposit', 'float') as [Deposit],
		[Table].[Column].value('./@bonus', 'float') as [Bonus]
	from @XmlData.nodes('/root/trans') as [Table]([Column])
	) as tmp


	select * from @TempTrans
  --Table contains all 12BET deposit Income Access Member
CREATE TABLE #MemberInfo(
	IBCCustID int primary key,     
	Currency int,
	UserName nvarchar(30),
	IBCUserName varchar(30),
	IBCAgentID int,
	Date smalldatetime,
	DepositCustID int,
	Turnover money,
	Winlost money,
	Deposit money,
	Bonus money
)  

--Get list member 
Insert into #MemberInfo(IBCCustID, Currency, UserName, IBCUserName, IBCAgentID, [Date], DepositCustID, Turnover, Winlost, Deposit, Bonus)
SELECT CustID, c.Currency, REPLACE(c.UserName2,'12bet$',''), c.username, recommend, tmp.DateImport
	, refcode2, Turnover, Winlost, Deposit, Bonus
FROM customer c with(nolock) 
	inner join @TempTrans as tmp on c.Username2 = '12bet$' + tmp.Username-- or c.Username2 = tmp.Username
WHERE roleid=1
	and recommend in (		
		select custid--Get list Agent Currency 04(Income Access members belong to these agents)
		from bodb02.dbo.customer c with(nolock)
		where roleid = 2
			and username in (select '12bet'+cast(currency as varchar(4))+'04' from exchange)
	)

BEGIN TRY

	BEGIN TRANSACTION

	--Delete Data for the date they want to import data if there is exists data
	DELETE FROM bodb_Report.dbo.MemberDailyIA WHERE winlostdate = @winlostdate and SportType = @CasinoId

	--Import Casino Data to MemberDailyIA table
	INSERT INTO bodb_Report.dbo.MemberDailyIA(
		WinlostDate,
		IBCCustID,
		Sporttype,
		UserName,
		IBCUserName,
		IBCAgentID,
		DepositCustID,
		Currency,
		Deposit,
		Withdrawal,	
		Bonus,
		Adjustment,
		Turnover,
		Outstanding,
		Winlost,
		AffExRate,
		MemberExRate,	
		DrawGame,
		PSP,
		Marketing,
		MemOddsFee
	)
	SELECT 
		[Date],
		IBCCustID, 
		@CasinoId as SportType, --SportsBook
		UserName,
		IBCUserName,
		IBCAgentID,
		DepositCustID,
		Currency,
		Deposit, 
		0 as Withdrawal, 	
		Bonus, 
		0 as Adjustment, 
		Turnover, 
		0 as Outstanding,
		-Winlost,
		ActualRate2,--Aff Ex.Rate
		ActualRate,	--Member Ex.Rate
		0 as DrawGame,
		(abs(Deposit) * e.DepositPercent) as PSP,--Because there is no withdrawal
		abs(Winlost) * @MarketingPercent as Marketing,	
		abs(Winlost) * @OddsFeePercent as MemOddsFee
	
	FROM #MemberInfo m with (nolock)
		inner join @AffExchange e on e.ExchangeID=m.Currency
	WHERE  Deposit<>0 or			  
		   TurnOver<>0 or	
		   Bonus<>0 or
			Winlost<>0    
		
	COMMIT TRANSACTION     
END TRY
BEGIN CATCH
	SELECT @ErrCode = ERROR_NUMBER(),
        @ErrMsg = ERROR_MESSAGE()
	-- Test whether the transaction is uncommittable.
    ROLLBACK TRANSACTION
END CATCH

drop table #MemberInfo

GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberDailyCasino_IA] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailyCasino_IA] TO [vnteam]