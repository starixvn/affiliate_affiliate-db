ALTER PROCEDURE [dbo].[AffAdmin_CommissionSettle]
	@UserId int=0, 
	@AffName NVARCHAR(100) = NULL,
	@AffTypes varchar(100) = NULL,
	@CommGroups varchar(1000) = NULL,
	@PreferLanguages varchar(1000) = NULL,
	@Currencies varchar(100) = NULL,	
	@BaseCurrency tinyint = 0,
	@SortBy tinyint = 0,
	@ExcludeTest bit = 1,
	@IsITAdmin bit = 0
AS
/*    
Task : Commission Report - Company View     
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
                
Param's Explanation: 
• @UserId: Admin user id
• @AffName: Affiliate username
• @AffTypes: List affilaite type
• @CommGroups: List Commission group
• @PreferLanguages: list preference language
• @Currencies: List currencies
• @FromDate: From date
• @ToDate: To date
• @SortBy: Dropdown list Sort By
	- 0: Commission
	- 1: Active Players
	- 3: Deposit
	- 4: Withdrawal
	- 5: Turnover
	- 6: Winloss
	- Note: Order by field must be converted to system exchange rate.
• @ExcludeTest: not include test accounts if true.
*/    

SET NOCOUNT ON 

DECLARE @FromDate smalldatetime, @ToDate smalldatetime, @CurrentDate datetime, @MaxCalculatedDate datetime, @PreviousMonth datetime
		, @AffectedRows int, @AffId int, @count int, @SystemExchangeId int, @GroupId int, @GroupName nvarchar(100)
		, @Amount money
		, @SportsbookAmount money, @SportsbookCommission decimal, @SportsbookQualifiedMember decimal
		, @NumberGameAmount money, @NumberGameCommission decimal, @NumberGameQualifiedMember decimal
		, @LiveCasinoAmount money, @LiveCasinoCommission decimal, @LiveCasinoQualifiedMember decimal
		, @RNGCasinoAmount money, @RNGCasinoCommission decimal, @RNGCasinoQualifiedMember decimal

--Reset todate to ending of date
SELECT	@ToDate = dbo.Aff_GetLastDayOfMonth(@ToDate)
		, @CurrentDate = CURRENT_TIMESTAMP
		, @PreviousMonth = DATEADD(m, -1, @CurrentDate)
		, @SystemExchangeId = [dbo].[Aff_GetSystemCurrencyID]()

Select @MaxCalculatedDate = isnull(max(WinlostDate), '2013-08-01') from AffCommission nolock

-- Get productid
Declare @SportsbookId int, @NumberGame int, @LiveCasino int, @RNGCasino int
Select	@SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		, @NumberGame = dbo.[Aff_GetProductID]('Number Game')
		, @LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		, @RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

Declare @Result Table(AffId int, Status varchar(50), WinlostDate datetime, Username varchar(50), ExchangeId int, Currency varchar(5), GroupID int, GroupName nvarchar(100)
					, Commission money, CommissionBase money, CashbackPercent decimal, CashbackAmount money,  CashbackAmountBase money
					, SportsbookWinloss money, SportsbookQM int, SportsbookCommissionPercent decimal, SportsbookCommission money
					, SportsbookWinlossBase money, SportsbookCommissionBase money
					, NumberGameWinloss money, NumberGameQM int, NumberGameCommissionPercent decimal, NumberGameCommission money
					, NumberGameWinlossBase money, NumberGameCommissionBase money
					, LiveCasinoWinloss money, LiveCasinoQM int, LiveCasinoCommissionPercent decimal, LiveCasinoCommission money
					, LiveCasinoWinlossBase money, LiveCasinoCommissionBase money					
					, RNGCasinoWinloss money, RNGCasinoQM int, RNGCasinoCommissionPercent decimal, RNGCasinoCommission money
					, RNGCasinoWinlossBase money, RNGCasinoCommissionBase money)

----For the month(s) that are not calculated
INSERT INTO @Result(AffId, Status, WinlostDate, Username, ExchangeId, Currency
					, SportsbookWinloss, SportsbookWinlossBase
					, NumberGameWinloss, NumberGameWinlossBase
					, LiveCasinoWinloss, LiveCasinoWinlossBase
					, RNGCasinoWinloss, RNGCasinoWinlossBase)
Select	ad.AffId, t.Status, dateadd(m, datediff(m, 0, Winlostdate), 0) as WinlostDate, t.Username, t.ExchangeId, t.Currency
		-----Sportsbook
		, SUM(CASE WHEN ad.ProductID = @SportsbookId then MemWinlost_aff ELSE 0 END) as SportsbookWinloss
		, SUM(CASE WHEN ad.ProductID = @SportsbookId then MemWinlost ELSE 0 END) as SportsbookWinlossBase
		-----Number Game
		, SUM(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost_aff ELSE 0 END) as NumberGameWinloss
		, SUM(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost ELSE 0 END) as NumberGameWinlossBase
		-----Live Casino
		, SUM(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost_aff ELSE 0 END) as LiveCasinoWinloss
		, SUM(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost ELSE 0 END) as LiveCasinoWinlossBase
		-----RNG Casino
		, SUM(CASE WHEN ad.ProductID = @RNGCasino then ad.MemWinlost_aff ELSE 0 END) as RNGCasinoWinloss
		, SUM(CASE WHEN ad.ProductID = @RNGCasino then MemWinlost ELSE 0 END) as RNGCasinoWinlossBase
From AffDailySummary ad with (nolock)
	inner JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
				as t on ad.AffId = t.AffId and DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
Where WinlostDate > @MaxCalculatedDate
Group BY ad.AffId, t.Status, dateadd(m, datediff(m, 0, Winlostdate), 0), t.Username, t.ExchangeId, t.Currency

select @AffectedRows=@@ROWCOUNT--ALL Rows that are not calculated

--Calculate commission Previous month that is not calculated yet
IF (DateDiff(m, @MaxCalculatedDate, @CurrentDate) = 2)
BEGIN
	Declare @Month int, @Year int, @ExchangeId int

	select top(1) @AffId = AffID, @ExchangeId = ExchangeId
	from @Result
	where Commission is null
		and DATEDIFF(m, @PreviousMonth, WinlostDate) = 0

	Select	@Month = MONTH(@PreviousMonth), @Year = YEAR(@PreviousMonth), @count=0

	while(@AffId is not null and @count<@AffectedRows)
	begin
		--------All Product----------
		Select	@SportsbookAmount = (Case WHEN @SportsbookId = ProductID THEN Amount ELSE 0 End)
				, @SportsbookCommission = (Case WHEN @SportsbookId = ProductID THEN commission ELSE 0 End)
				, @SportsbookQualifiedMember = (Case WHEN @SportsbookId = ProductID THEN TotalQM ELSE 0 End)
				, @NumberGameAmount = (Case WHEN @NumberGame = ProductID THEN Amount ELSE 0 End)
				, @NumberGameCommission = (Case WHEN @NumberGame = ProductID THEN commission ELSE 0 End)
				, @NumberGameQualifiedMember = (Case WHEN @NumberGame = ProductID THEN TotalQM ELSE 0 End)
				, @LiveCasinoAmount = (Case WHEN @LiveCasino = ProductID THEN Amount ELSE 0 End)
				, @LiveCasinoCommission = (Case WHEN @LiveCasino = ProductID THEN commission ELSE 0 End)
				, @LiveCasinoQualifiedMember = (Case WHEN @LiveCasino = ProductID THEN TotalQM ELSE 0 End)
				, @RNGCasinoAmount = (Case WHEN @RNGCasino = ProductID THEN Amount ELSE 0 End)
				, @RNGCasinoCommission = (Case WHEN @RNGCasino = ProductID THEN commission ELSE 0 End)
				, @RNGCasinoQualifiedMember = (Case WHEN @RNGCasino = ProductID THEN TotalQM ELSE 0 End)
		From [dbo].[Aff_CommissionForMonth](@AffId, @Month, @Year)

		Select @Amount = @SportsbookAmount + @NumberGameAmount + @LiveCasinoAmount + @RNGCasinoAmount

		Select @GroupId = cg.GroupId, @GroupName = cg.GroupName
		From @Result r
			INNER JOIN AffGroupHistory ag with (NOLOCK) on r.AffId = ag.AffID and DATEDIFF(m, r.WinlostDate, ag.MonthDate) = 0
			INNER JOIN CommGroupHistory cg with (NOLOCK) on ag.GroupID = cg.GroupID and ag.MonthDate = cg.MonthDate
		Where r.AffID = @AffId 
				and DATEDIFF(m, @PreviousMonth, WinlostDate) = 0

		update r
		set r.GroupName =					@GroupName
			, r.GroupId =					@GroupId
			, CashbackPercent =				isnull(d.DeductedPercentage, 0)
			, CashbackAmount =				isnull(a.Amount, 0)
			, CashbackAmountBase =			isnull(a.Amount * a.SysExRate, 0)
			, Commission =					isnull(@Amount - isnull((d.DeductedPercentage * a.Amount), 0), 0)--All Product
			, CommissionBase =				isnull((@Amount - isnull((d.DeductedPercentage * a.Amount), 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			, SportsbookCommission =		isnull(@SportsbookAmount, 0)
			, SportsbookQM =				isnull(@SportsbookQualifiedMember, 0)
			, SportsbookCommissionPercent = isnull(@SportsbookCommission, 0)
			, SportsbookCommissionBase =	isnull(@SportsbookAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)

			, NumberGameCommission =		isnull(@NumberGameAmount,0)
			, NumberGameQM =				isnull(@NumberGameQualifiedMember, 0)
			, NumberGameCommissionPercent = isnull(@NumberGameCommission, 0)
			, NumberGameCommissionBase =	isnull(@NumberGameAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL),0)

			, LiveCasinoCommission =		isnull(@LiveCasinoAmount,0)
			, LiveCasinoQM =				isnull(@LiveCasinoQualifiedMember, 0)
			, LiveCasinoCommissionPercent = isnull(@LiveCasinoCommission, 0)
			, LiveCasinoCommissionBase =	isnull(@LiveCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL),0)

			, RNGCasinoCommission =			isnull(@RNGCasinoAmount,0)
			, RNGCasinoQM =					isnull(@RNGCasinoQualifiedMember, 0)
			, RNGCasinoCommissionPercent =	isnull(@RNGCasinoCommission, 0)
			, RNGCasinoCommissionBase =		isnull(@RNGCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL),0)
		From @Result r
			LEFT JOIN AffDeductionTransaction a with (nolock) on r.AffId = a.AffID and datediff(m, a.MonthDate, @PreviousMonth) = 0 and a.ProductID = 0
			LEFT JOIN DeductionSettingHistory d with (nolock)  on d.DeductionID=a.DTypeID and datediff(m, d.MonthDate, @PreviousMonth) = 0 and d.GroupID = r.GroupId
		Where r.AffID = @AffId 
				and DATEDIFF(m, @PreviousMonth, r.WinlostDate) = 0

		--Get next AffID
		select top(1) @AffId=AffID, @ExchangeId = ExchangeId
		from @Result
		where Commission is null
			and DATEDIFF(m, @PreviousMonth, WinlostDate) = 0

		set @count=@count+1
				
	end	
END

select top(1) @AffId=AffID
from @Result
where Commission is null
	and DATEDIFF(m, @CurrentDate, WinlostDate) = 0

select @count=0

	while(@AffId is not null and @count<@AffectedRows)
	BEGIN
		--------All Product----------
		Select	@SportsbookAmount = (Case WHEN @SportsbookId = ProductID THEN Amount ELSE 0 End)
				, @SportsbookCommission = (Case WHEN @SportsbookId = ProductID THEN commission ELSE 0 End)
				, @SportsbookQualifiedMember = (Case WHEN @SportsbookId = ProductID THEN TotalQM ELSE 0 End)
				, @NumberGameAmount = (Case WHEN @NumberGame = ProductID THEN Amount ELSE 0 End)
				, @NumberGameCommission = (Case WHEN @NumberGame = ProductID THEN commission ELSE 0 End)
				, @NumberGameQualifiedMember = (Case WHEN @NumberGame = ProductID THEN TotalQM ELSE 0 End)
				, @LiveCasinoAmount = (Case WHEN @LiveCasino = ProductID THEN Amount ELSE 0 End)
				, @LiveCasinoCommission = (Case WHEN @LiveCasino = ProductID THEN commission ELSE 0 End)
				, @LiveCasinoQualifiedMember = (Case WHEN @LiveCasino = ProductID THEN TotalQM ELSE 0 End)
				, @RNGCasinoAmount = (Case WHEN @RNGCasino = ProductID THEN Amount ELSE 0 End)
				, @RNGCasinoCommission = (Case WHEN @RNGCasino = ProductID THEN commission ELSE 0 End)
				, @RNGCasinoQualifiedMember = (Case WHEN @RNGCasino = ProductID THEN TotalQM ELSE 0 End)
		From [dbo].[Aff_CommissionForCurrentMonth](@AffId)

		Select @Amount = @SportsbookAmount + @NumberGameAmount + @LiveCasinoAmount + @RNGCasinoAmount
		
		Select @GroupId = cg.GroupId, @GroupName = cg.GroupName
		From @Result r
			INNER JOIN AffInfo AI WITH (NOLOCK) ON r.AffId = AI.AffID
			INNER JOIN CommGroup cg with (NOLOCK) on AI.GroupID = cg.GroupID
		Where r.AffID = @AffId 

		update r
		set GroupName =						@GroupName
			, r.GroupId =					@GroupId
			, CashbackPercent =				d.DeductedPercentage
			, CashbackAmount =				isnull(a.Amount, 0)
			, CashbackAmountBase =			isnull(a.Amount * SysExRate, 0)
			, Commission =					isnull(@Amount - ISNULL(d.DeductedPercentage * a.Amount, 0), 0)--All Product
			, CommissionBase =				isnull((@Amount - ISNULL(d.DeductedPercentage * a.Amount * a.SysExRate, 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)

			, SportsbookCommission =		isnull(@SportsbookAmount, 0)
			, SportsbookQM =				isnull(@SportsbookQualifiedMember, 0)
			, SportsbookCommissionPercent = isnull(@SportsbookCommission, 0)
			, SportsbookCommissionBase =	isnull(@SportsbookAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)

			, NumberGameCommission =		isnull(@NumberGameAmount,0)
			, NumberGameQM =				isnull(@NumberGameQualifiedMember, 0)
			, NumberGameCommissionPercent = isnull(@NumberGameCommission, 0)
			, NumberGameCommissionBase =	isnull(@NumberGameAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)

			, LiveCasinoCommission =		isnull(@LiveCasinoAmount,0)
			, LiveCasinoQM =				isnull(@LiveCasinoQualifiedMember, 0)
			, LiveCasinoCommissionPercent = isnull(@LiveCasinoCommission, 0)
			, LiveCasinoCommissionBase =	isnull(@LiveCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)

			, RNGCasinoCommission =			isnull(@RNGCasinoAmount,0)
			, RNGCasinoQM =					isnull(@RNGCasinoQualifiedMember, 0)
			, RNGCasinoCommissionPercent =	isnull(@RNGCasinoCommission, 0)
			, RNGCasinoCommissionBase =	isnull(@RNGCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
		From @Result r
			LEFT JOIN AffDeductionTransaction a with (nolock) on r.AffId = a.AffID and datediff(m, a.MonthDate, @CurrentDate) = 0 and a.ProductID = 0
			LEFT JOIN DeductionSetting d with (nolock)  on d.DeductionID=a.DTypeID  and d.GroupID = @GroupId
		Where r.AffID = @AffId 
				and DATEDIFF(m, @CurrentDate, WinlostDate) = 0

		--Get next AffID
		select top(1) @AffId=AffID
		from @Result
		where Commission is null
			and DATEDIFF(m, @CurrentDate, WinlostDate) = 0
				
		set @count=@count+1
	END

-------Return Data------------
-- Determine the order direction.
DECLARE @Direction INT
SET @Direction = (CASE @SortBy WHEN 0 THEN 1 ELSE -1 END )

;WITH ResTable AS
(	
	SELECT *, 
		ROW_NUMBER() OVER (ORDER BY 
							(CASE @SortBy
								WHEN 0 THEN AffID
								Else CommissionBase--Money after converted
							END)) AS RowNo
	FROM @Result
),
SortedResTable AS
(
	SELECT *, ROW_NUMBER() OVER (ORDER BY RowNo*@Direction) AS RowNum
	FROM ResTable	
)

SELECT * 
from SortedResTable
ORDER BY WinlostDate, RowNum


GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommissionSettle] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommissionSettle] TO [vnteam] AS [dbo]