USE [Affiliate_AoncashUAT]
GO
/****** Object:  StoredProcedure [dbo].[AffAdmin_CommissionSettle]    Script Date: 12/19/2013 8:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
BEGIN
	SET NOCOUNT ON 

	DECLARE @FromDate smalldatetime, @ToDate smalldatetime, @CurrentDate datetime, @MaxCalculatedDate datetime, @PreviousMonth datetime
			, @AffectedRows int, @AffId int, @count int, @SystemExchangeId int, @GroupId int, @GroupName nvarchar(100)
			, @Amount money
			, @SportsbookAmount money, @SportsbookCommission decimal, @SportsbookQualifiedMember decimal
			, @NumberGameAmount money, @NumberGameCommission decimal, @NumberGameQualifiedMember decimal
			, @LiveCasinoAmount money, @LiveCasinoCommission decimal, @LiveCasinoQualifiedMember decimal
			, @RNGCasinoAmount money, @RNGCasinoCommission decimal, @RNGCasinoQualifiedMember DECIMAL
        
	--Reset todate to ending of date
	SELECT	@ToDate = GETDATE()
			, @CurrentDate = CURRENT_TIMESTAMP
			, @PreviousMonth = DATEADD(m, -1, @CurrentDate)
			, @SystemExchangeId = [dbo].[Aff_GetSystemCurrencyID]()

	Select @MaxCalculatedDate = isnull(max(WinlostDate), @PreviousMonth) from AffCommission nolock
	SET @FromDate = @MaxCalculatedDate + 1;

	-- Get productid
	Declare @SportsbookId int, @NumberGame int, @LiveCasino int, @RNGCasino int
	Select	@SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
			, @NumberGame = dbo.[Aff_GetProductID]('Number Game')
			, @LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
			, @RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

	Declare @Result Table(AffId int, Status varchar(50), WinlostDate datetime, Username varchar(50), ExchangeId int, Currency varchar(5), GroupID int, GroupName nvarchar(100)
						, Commission money, CommissionBase money, CashbackPercent decimal(9,8), CashbackAmount money,  CashbackAmountBase money
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
			Select	@SportsbookAmount = (Case WHEN @SportsbookId = ProductID THEN Amount ELSE @SportsbookAmount End)
					, @SportsbookCommission = (Case WHEN @SportsbookId = ProductID THEN commission ELSE @SportsbookCommission End)
					, @SportsbookQualifiedMember = (Case WHEN @SportsbookId = ProductID THEN TotalQM ELSE @SportsbookQualifiedMember End)
					, @NumberGameAmount = (Case WHEN @NumberGame = ProductID THEN Amount ELSE @NumberGameAmount End)
					, @NumberGameCommission = (Case WHEN @NumberGame = ProductID THEN commission ELSE @NumberGameCommission End)
					, @NumberGameQualifiedMember = (Case WHEN @NumberGame = ProductID THEN TotalQM ELSE @NumberGameQualifiedMember End)
					, @LiveCasinoAmount = (Case WHEN @LiveCasino = ProductID THEN Amount ELSE @LiveCasinoAmount End)
					, @LiveCasinoCommission = (Case WHEN @LiveCasino = ProductID THEN commission ELSE @LiveCasinoCommission End)
					, @LiveCasinoQualifiedMember = (Case WHEN @LiveCasino = ProductID THEN TotalQM ELSE @LiveCasinoQualifiedMember End)
					, @RNGCasinoAmount = (Case WHEN @RNGCasino = ProductID THEN Amount ELSE @RNGCasinoAmount End)
					, @RNGCasinoCommission = (Case WHEN @RNGCasino = ProductID THEN commission ELSE @RNGCasinoCommission End)
					, @RNGCasinoQualifiedMember = (Case WHEN @RNGCasino = ProductID THEN TotalQM ELSE @RNGCasinoQualifiedMember End)
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
				, CashbackPercent =				isnull(tmp.DeductedPercentage, 0)
				, CashbackAmount =				isnull(tmp.CashAmount, 0)
				, CashbackAmountBase =			isnull(tmp.CashAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, @PreviousMonth), 0)

				, Commission =					isnull(@Amount,0) - [dbo].[Aff_GetAffDeductionAll] (@AffID, @PreviousMonth)--All Product
				, CommissionBase =				isnull((@Amount - isnull((tmp.DeductedPercentage * tmp.CashAmount), 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, @PreviousMonth), 0)

				, SportsbookCommission =		isnull(@SportsbookAmount, 0)
				, SportsbookQM =				isnull(@SportsbookQualifiedMember, 0)
				, SportsbookCommissionPercent = isnull(@SportsbookCommission, 0)
				, SportsbookCommissionBase =	isnull(@SportsbookAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, @PreviousMonth), 0)

				, NumberGameCommission =		isnull(@NumberGameAmount,0)
				, NumberGameQM =				isnull(@NumberGameQualifiedMember, 0)
				, NumberGameCommissionPercent = isnull(@NumberGameCommission, 0)
				, NumberGameCommissionBase =	isnull(@NumberGameAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, @PreviousMonth),0)

				, LiveCasinoCommission =		isnull(@LiveCasinoAmount,0)
				, LiveCasinoQM =				isnull(@LiveCasinoQualifiedMember, 0)
				, LiveCasinoCommissionPercent = isnull(@LiveCasinoCommission, 0)
				, LiveCasinoCommissionBase =	isnull(@LiveCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, @PreviousMonth),0)

				, RNGCasinoCommission =			isnull(@RNGCasinoAmount,0)
				, RNGCasinoQM =					isnull(@RNGCasinoQualifiedMember, 0)
				, RNGCasinoCommissionPercent =	isnull(@RNGCasinoCommission, 0)
				, RNGCasinoCommissionBase =		isnull(@RNGCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, @PreviousMonth),0)
			From @Result r
			LEFT JOIN (
				select a.AffID, a.Amount as CashAmount, b.DeductedPercentage
				from AffDeductionTransaction  a with (nolock)
					inner join AffGroupHistory ai (nolock) on ai.affid=a.affid and datediff(m,a.MonthDate,ai.MonthDate)=0
					join DeductionSettingHistory b with (nolock) on a.DTypeID=b.DeductionID
					join DeductionType c with (nolock) on b.DeductionID=c.DTypeID
				where c.[DTypeName]='Cashback'
					and datediff(m, a.MonthDate, @PreviousMonth) = 0 and a.ProductID = 0
					and b.GroupID=@GroupId
				) tmp ON r.AffID = tmp.AffID
			Where r.AffID = @AffId 
					and DATEDIFF(m, @PreviousMonth, r.WinlostDate) = 0
			--LEFT JOIN AffDeductionTransaction a with (nolock) on r.AffId = a.AffID and datediff(m, a.MonthDate, @PreviousMonth) = 0 and a.ProductID = 0
			--LEFT JOIN DeductionSettingHistory d with (nolock)  on d.DeductionID=a.DTypeID and datediff(m, d.MonthDate, @PreviousMonth) = 0 and d.GroupID = r.GroupId
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
		Select	@SportsbookAmount = (Case WHEN @SportsbookId = ProductID THEN Amount ELSE @SportsbookAmount End)
				, @SportsbookCommission = (Case WHEN @SportsbookId = ProductID THEN commission ELSE @SportsbookCommission End)
				, @SportsbookQualifiedMember = (Case WHEN @SportsbookId = ProductID THEN TotalQM ELSE @SportsbookQualifiedMember End)
				, @NumberGameAmount = (Case WHEN @NumberGame = ProductID THEN Amount ELSE @NumberGameAmount End)
				, @NumberGameCommission = (Case WHEN @NumberGame = ProductID THEN commission ELSE @NumberGameCommission End)
				, @NumberGameQualifiedMember = (Case WHEN @NumberGame = ProductID THEN TotalQM ELSE @NumberGameQualifiedMember End)
				, @LiveCasinoAmount = (Case WHEN @LiveCasino = ProductID THEN Amount ELSE @LiveCasinoAmount End)
				, @LiveCasinoCommission = (Case WHEN @LiveCasino = ProductID THEN commission ELSE @LiveCasinoCommission End)
				, @LiveCasinoQualifiedMember = (Case WHEN @LiveCasino = ProductID THEN TotalQM ELSE @LiveCasinoQualifiedMember End)
				, @RNGCasinoAmount = (Case WHEN @RNGCasino = ProductID THEN Amount ELSE @RNGCasinoAmount End)
				, @RNGCasinoCommission = (Case WHEN @RNGCasino = ProductID THEN commission ELSE @RNGCasinoCommission End)
				, @RNGCasinoQualifiedMember = (Case WHEN @RNGCasino = ProductID THEN TotalQM ELSE @RNGCasinoQualifiedMember End)
		From [dbo].[Aff_CommissionForCurrentMonth](@AffId)

		Select @Amount = @SportsbookAmount + @NumberGameAmount + @LiveCasinoAmount + @RNGCasinoAmount
		
		Select @GroupId = cg.GroupId, @GroupName = cg.GroupName
		From @Result r
			INNER JOIN AffInfo AI WITH (NOLOCK) ON r.AffId = AI.AffID
			INNER JOIN CommGroup cg with (NOLOCK) on AI.GroupID = cg.GroupID
		Where r.AffID = @AffId 

		select a.AffID, a.Amount as CashAmount, b.DeductedPercentage
			from AffDeductionTransaction a with (nolock)
				join DeductionSetting b  with (nolock) on a.DTypeID=b.DeductionID
				join DeductionType c with (nolock) on b.DeductionID=c.DTypeID
			where c.[DTypeName]='Cashback'
				and datediff(m, a.MonthDate, @CurrentDate) = 0 and a.ProductID = 0
				and b.GroupID=@GroupId

		update r
		set GroupName =						@GroupName
			, r.GroupId =					@GroupId
			, CashbackPercent =				tmp.DeductedPercentage
			, CashbackAmount =				isnull(tmp.CashAmount, 0)
			, CashbackAmountBase =			isnull(tmp.CashAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)

			, Commission =					isnull(@Amount,0) - [dbo].[Aff_GetAffDeductionAll] (@AffID, @CurrentDate)--All Product
			, CommissionBase =				isnull((@Amount - isnull((tmp.DeductedPercentage * tmp.CashAmount), 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)

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
		LEFT JOIN (
			select a.AffID, a.Amount as CashAmount, b.DeductedPercentage
			from AffDeductionTransaction a with (nolock)
				join DeductionSetting b  with (nolock) on a.DTypeID=b.DeductionID
				join DeductionType c with (nolock) on b.DeductionID=c.DTypeID
			where c.[DTypeName]='Cashback'
				and datediff(m, a.MonthDate, @CurrentDate) = 0 and a.ProductID = 0
				and b.GroupID=@GroupId
			) tmp ON r.AffID = tmp.AffID
		Where r.AffID = @AffId 
				and DATEDIFF(m, @CurrentDate, WinlostDate) = 0

		--LEFT JOIN AffDeductionTransaction a with (nolock) on r.AffId = a.AffID and datediff(m, a.MonthDate, @CurrentDate) = 0 and a.ProductID = 0 and a.DTypeID=5
		--LEFT JOIN DeductionSetting d with (nolock)  on d.DeductionID=a.DTypeID  and d.GroupID = @GroupId
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
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommissionSettle] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommissionSettle] TO [vnteam] AS [dbo]