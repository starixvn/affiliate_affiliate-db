ALTER PROCEDURE [dbo].[AffAdmin_CommissionSettle] 
	@UserId				INT = 0
	,@AffName			NVARCHAR(100) = NULL
	,@AffTypes			VARCHAR(100) = NULL
	,@CommGroups		VARCHAR(1000) = NULL
	,@PreferLanguages	VARCHAR(1000) = NULL
	,@Currencies		VARCHAR(100) = NULL
	,@BaseCurrency		TINYINT = 0
	,@SortBy			TINYINT = 0
	,@ExcludeTest		BIT = 1
	,@IsITAdmin			BIT = 0
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

	DECLARE @FromDate SMALLDATETIME
		,@ToDate SMALLDATETIME
		,@CurrentDate DATETIME
		,@MaxCalculatedDate DATETIME
		,@PreviousMonth DATETIME
		,@AffectedRows INT
		,@AffId INT
		,@count INT
		,@SystemExchangeId INT
		,@GroupId INT
		,@GroupName NVARCHAR(100)
		,@Amount MONEY
		,@SportsbookAmount MONEY
		,@SportsbookCommission DECIMAL(9, 8)
		,@SportsbookQualifiedMember DECIMAL
		,@NumberGameAmount MONEY
		,@NumberGameCommission DECIMAL(9, 8)
		,@NumberGameQualifiedMember DECIMAL
		,@LiveCasinoAmount MONEY
		,@LiveCasinoCommission DECIMAL(9, 8)
		,@LiveCasinoQualifiedMember DECIMAL
		,@RNGCasinoAmount MONEY
		,@RNGCasinoCommission DECIMAL(9, 8)
		,@RNGCasinoQualifiedMember DECIMAL

	--Reset todate to ending of date
	SELECT @ToDate = GETDATE()
		,@CurrentDate = CURRENT_TIMESTAMP
		,@PreviousMonth = DATEADD(m, - 1, @CurrentDate)
		,@SystemExchangeId = [dbo].[Aff_GetSystemCurrencyID]()

	SELECT @MaxCalculatedDate = isnull(max(WinlostDate), @PreviousMonth)
	FROM AffCommission NOLOCK

	SET @FromDate = DATEADD(d, 1, @MaxCalculatedDate);

	-- Get productid
	DECLARE @SportsbookId INT
		,@NumberGame INT
		,@LiveCasino INT
		,@RNGCasino INT

	SELECT @SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

	DECLARE @Result TABLE (
		AffId INT
		,STATUS VARCHAR(50)
		,WinlostDate DATETIME
		,Username VARCHAR(50)
		,ExchangeId INT
		,Currency VARCHAR(5)
		,GroupID INT
		,GroupName NVARCHAR(100)
		,Commission MONEY
		,CommissionBase MONEY
		,CashbackPercent DECIMAL(9, 8)
		,CashbackAmount MONEY
		,CashbackAmountBase MONEY
		,SportsbookWinloss MONEY
		,SportsbookQM INT
		,SportsbookCommissionPercent DECIMAL(9, 8)
		,SportsbookCommission MONEY
		,SportsbookWinlossBase MONEY
		,SportsbookCommissionBase MONEY
		,NumberGameWinloss MONEY
		,NumberGameQM INT
		,NumberGameCommissionPercent DECIMAL(9, 8)
		,NumberGameCommission MONEY
		,NumberGameWinlossBase MONEY
		,NumberGameCommissionBase MONEY
		,LiveCasinoWinloss MONEY
		,LiveCasinoQM INT
		,LiveCasinoCommissionPercent DECIMAL(9, 8)
		,LiveCasinoCommission MONEY
		,LiveCasinoWinlossBase MONEY
		,LiveCasinoCommissionBase MONEY
		,RNGCasinoWinloss MONEY
		,RNGCasinoQM INT
		,RNGCasinoCommissionPercent DECIMAL(9, 8)
		,RNGCasinoCommission MONEY
		,RNGCasinoWinlossBase MONEY
		,RNGCasinoCommissionBase MONEY
		,EnableCashback BIT DEFAULT 1
		)

	----For the month(s) that are not calculated
	INSERT INTO @Result (
		AffId
		,STATUS
		,WinlostDate
		,Username
		,ExchangeId
		,Currency
		,SportsbookWinloss
		,SportsbookWinlossBase
		,NumberGameWinloss
		,NumberGameWinlossBase
		,LiveCasinoWinloss
		,LiveCasinoWinlossBase
		,RNGCasinoWinloss
		,RNGCasinoWinlossBase
		)
	SELECT ad.AffId
		,t.STATUS
		,dateadd(m, datediff(m, 0, Winlostdate), 0) AS WinlostDate
		,t.Username
		,t.ExchangeId
		,t.Currency
		-----Sportsbook
		,SUM(CASE 
				WHEN ad.ProductID = @SportsbookId THEN MemWinlost_aff
				ELSE 0
				END) AS SportsbookWinloss
		,SUM(CASE 
				WHEN ad.ProductID = @SportsbookId THEN MemWinlost
				ELSE 0
				END) AS SportsbookWinlossBase
		-----Number Game
		,SUM(CASE 
				WHEN ad.ProductID = @NumberGame THEN ad.MemWinlost_aff
				ELSE 0
				END) AS NumberGameWinloss
		,SUM(CASE 
				WHEN ad.ProductID = @NumberGame THEN ad.MemWinlost
				ELSE 0
				END) AS NumberGameWinlossBase
		-----Live Casino
		,SUM(CASE 
				WHEN ad.ProductID = @LiveCasino THEN ad.MemWinlost_aff
				ELSE 0
				END) AS LiveCasinoWinloss
		,SUM(CASE 
				WHEN ad.ProductID = @LiveCasino THEN ad.MemWinlost
				ELSE 0
				END) AS LiveCasinoWinlossBase
		-----RNG Casino
		,SUM(CASE 
				WHEN ad.ProductID = @RNGCasino THEN ad.MemWinlost_aff
				ELSE 0
				END) AS RNGCasinoWinloss
		,SUM(CASE 
				WHEN ad.ProductID = @RNGCasino THEN MemWinlost
				ELSE 0
				END) AS RNGCasinoWinlossBase
	FROM AffDailySummary ad WITH (NOLOCK)
		INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @CurrentDate) AS t
		ON ad.AffId = t.AffId
			AND DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
		INNER JOIN (
		SELECT AffId
			,COUNT(UserName) MemTrans
		FROM MemberDaily WITH (NOLOCK)
		WHERE WinlostDate > @MaxCalculatedDate
		GROUP BY AffId
		HAVING COUNT(UserName) > 0
		) AS trans
		ON ad.AffId = trans.AffId
	WHERE WinlostDate > @MaxCalculatedDate
	GROUP BY ad.AffId
		,t.STATUS
		,dateadd(m, datediff(m, 0, Winlostdate), 0)
		,t.Username
		,t.ExchangeId
		,t.Currency

	SELECT @AffectedRows = @@ROWCOUNT --ALL Rows that are not calculated

	--Calculate commission Previous month that is not calculated yet
	IF (DateDiff(m, @MaxCalculatedDate, @CurrentDate) >= 2)
	BEGIN
		DECLARE @Month INT
			,@Year INT
			,@ExchangeId INT

		SELECT TOP (1) @AffId = AffID
			,@ExchangeId = ExchangeId
		FROM @Result
		WHERE Commission IS NULL
			AND DATEDIFF(m, @PreviousMonth, WinlostDate) = 0

		SELECT @Month = MONTH(@PreviousMonth)
			,@Year = YEAR(@PreviousMonth)
			,@count = 0

		WHILE (
				@AffId IS NOT NULL
				AND @count < @AffectedRows
				)
		BEGIN
			--------All Product----------
			SELECT @SportsbookAmount = (CASE 
					WHEN @SportsbookId = ProductID THEN Amount
					ELSE @SportsbookAmount END
					)
				,@SportsbookCommission = (CASE 
					WHEN @SportsbookId = ProductID THEN commission
					ELSE @SportsbookCommission END
					)
				,@SportsbookQualifiedMember = (CASE 
					WHEN @SportsbookId = ProductID THEN TotalQM
					ELSE @SportsbookQualifiedMember END
					)
				,@NumberGameAmount = (CASE 
					WHEN @NumberGame = ProductID THEN Amount
					ELSE @NumberGameAmount END
					)
				,@NumberGameCommission = (CASE 
					WHEN @NumberGame = ProductID THEN commission
					ELSE @NumberGameCommission END
					)
				,@NumberGameQualifiedMember = (CASE 
					WHEN @NumberGame = ProductID THEN TotalQM
					ELSE @NumberGameQualifiedMember END
					)
				,@LiveCasinoAmount = (CASE 
					WHEN @LiveCasino = ProductID THEN Amount
					ELSE @LiveCasinoAmount END
					)
				,@LiveCasinoCommission = (CASE 
					WHEN @LiveCasino = ProductID THEN commission
					ELSE @LiveCasinoCommission END
					)
				,@LiveCasinoQualifiedMember = (CASE 
					WHEN @LiveCasino = ProductID THEN TotalQM
					ELSE @LiveCasinoQualifiedMember END
					)
				,@RNGCasinoAmount = (CASE 
					WHEN @RNGCasino = ProductID THEN Amount
					ELSE @RNGCasinoAmount END
					)
				,@RNGCasinoCommission = (CASE 
					WHEN @RNGCasino = ProductID THEN commission
					ELSE @RNGCasinoCommission END
					)
				,@RNGCasinoQualifiedMember = (CASE 
					WHEN @RNGCasino = ProductID THEN TotalQM
					ELSE @RNGCasinoQualifiedMember END
					)
			FROM [dbo].[Aff_CommissionForMonth](@AffId, @Month, @Year)

			SELECT @Amount = isnull(@SportsbookAmount, 0) + isnull(@NumberGameAmount, 0) + isnull(@LiveCasinoAmount, 0) + isnull(@RNGCasinoAmount, 0)

			--print @Amount
			SELECT @GroupId = cg.GroupId
				,@GroupName = cg.GroupName
			FROM @Result r
				INNER JOIN AffGroupHistory ag WITH (NOLOCK)
				ON r.AffId = ag.AffID
					AND DATEDIFF(m, r.WinlostDate, ag.MonthDate) = 0
				INNER JOIN CommGroupHistory cg WITH (NOLOCK)
				ON ag.GroupID = cg.GroupID
					AND ag.MonthDate = cg.MonthDate
			WHERE r.AffID = @AffId
				AND DATEDIFF(m, @PreviousMonth, WinlostDate) = 0

			UPDATE r
			SET r.GroupName = @GroupName
				,r.GroupId = @GroupId
				,CashbackPercent = isnull(tmp.DeductedPercentage, 0)
				,CashbackAmount = isnull(tmp.CashAmount, 0)
				,CashbackAmountBase = isnull(tmp.CashAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,Commission = isnull(@Amount, 0) - [dbo].[Aff_GetAffDeductionAll](@AffID, @PreviousMonth) --All Product
				,CommissionBase = isnull((@Amount - isnull((tmp.DeductedPercentage * tmp.CashAmount), 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,SportsbookCommission = isnull(@SportsbookAmount, 0)
				,SportsbookQM = isnull(@SportsbookQualifiedMember, 0)
				,SportsbookCommissionPercent = isnull(@SportsbookCommission, 0)
				,SportsbookCommissionBase = isnull(@SportsbookAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,NumberGameCommission = isnull(@NumberGameAmount, 0)
				,NumberGameQM = isnull(@NumberGameQualifiedMember, 0)
				,NumberGameCommissionPercent = isnull(@NumberGameCommission, 0)
				,NumberGameCommissionBase = isnull(@NumberGameAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,LiveCasinoCommission = isnull(@LiveCasinoAmount, 0)
				,LiveCasinoQM = isnull(@LiveCasinoQualifiedMember, 0)
				,LiveCasinoCommissionPercent = isnull(@LiveCasinoCommission, 0)
				,LiveCasinoCommissionBase = isnull(@LiveCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,RNGCasinoCommission = isnull(@RNGCasinoAmount, 0)
				,RNGCasinoQM = isnull(@RNGCasinoQualifiedMember, 0)
				,RNGCasinoCommissionPercent = isnull(@RNGCasinoCommission, 0)
				,RNGCasinoCommissionBase = isnull(@RNGCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,EnableCashback = isnull(tmp.DeductedPercentage, 0)
			FROM @Result r
				LEFT JOIN (
				SELECT a.AffID
					,a.Amount AS CashAmount
					,b.DeductedPercentage
				FROM AffDeductionTransaction a WITH (NOLOCK)
					INNER JOIN AffGroupHistory ai(NOLOCK)
					ON ai.affid = a.affid
						AND datediff(m, a.MonthDate, ai.MonthDate) = 0
					JOIN DeductionSettingHistory b WITH (NOLOCK)
					ON a.DTypeID = b.DeductionID
						AND ai.groupid = b.groupid
						AND ai.MonthDate = b.MonthDate
					JOIN DeductionType c WITH (NOLOCK)
					ON b.DeductionID = c.DTypeID
				WHERE c.[DTypeName] = 'Cashback'
					AND datediff(m, a.MonthDate, @PreviousMonth) = 0
					AND a.ProductID = 0
					AND b.GroupID = @GroupId
				) tmp
				ON r.AffID = tmp.AffID
			WHERE r.AffID = @AffId
				AND DATEDIFF(m, @PreviousMonth, r.WinlostDate) = 0

			--LEFT JOIN AffDeductionTransaction a with (nolock) on r.AffId = a.AffID and datediff(m, a.MonthDate, @PreviousMonth) = 0 and a.ProductID = 0
			--LEFT JOIN DeductionSettingHistory d with (nolock)  on d.DeductionID=a.DTypeID and datediff(m, d.MonthDate, @PreviousMonth) = 0 and d.GroupID = r.GroupId
			--Get next AffID
			SELECT TOP (1) @AffId = AffID
				,@ExchangeId = ExchangeId
			FROM @Result
			WHERE Commission IS NULL
				AND DATEDIFF(m, @PreviousMonth, WinlostDate) = 0

			SET @count = @count + 1

			--reset value
			SELECT @SportsbookAmount = 0
				,@SportsbookCommission = 0
				,@SportsbookQualifiedMember = 0
				,@NumberGameAmount = 0
				,@NumberGameCommission = 0
				,@NumberGameQualifiedMember = 0
				,@LiveCasinoAmount = 0
				,@LiveCasinoCommission = 0
				,@LiveCasinoQualifiedMember = 0
				,@RNGCasinoAmount = 0
				,@RNGCasinoCommission = 0
				,@RNGCasinoQualifiedMember = 0;
		END
	END

	--update to current month
	SELECT TOP (1) @AffId = AffID
		,@ExchangeId = ExchangeId
	FROM @Result
	WHERE Commission IS NULL
		AND DATEDIFF(m, @CurrentDate, WinlostDate) = 0

	SELECT @count = 0

	WHILE (
			@AffId IS NOT NULL
			AND @count < @AffectedRows
			)
	BEGIN
		--------All Product----------
		SELECT @SportsbookAmount = (CASE 
				WHEN @SportsbookId = ProductID THEN Amount
				ELSE @SportsbookAmount END
				)
			,@SportsbookCommission = (CASE 
				WHEN @SportsbookId = ProductID THEN commission
				ELSE @SportsbookCommission END
				)
			,@SportsbookQualifiedMember = (CASE 
				WHEN @SportsbookId = ProductID THEN TotalQM
				ELSE @SportsbookQualifiedMember END
				)
			,@NumberGameAmount = (CASE 
				WHEN @NumberGame = ProductID THEN Amount
				ELSE @NumberGameAmount END
				)
			,@NumberGameCommission = (CASE 
				WHEN @NumberGame = ProductID THEN commission
				ELSE @NumberGameCommission END
				)
			,@NumberGameQualifiedMember = (CASE 
				WHEN @NumberGame = ProductID THEN TotalQM
				ELSE @NumberGameQualifiedMember END
				)
			,@LiveCasinoAmount = (CASE 
				WHEN @LiveCasino = ProductID THEN Amount
				ELSE @LiveCasinoAmount END
				)
			,@LiveCasinoCommission = (CASE 
				WHEN @LiveCasino = ProductID THEN commission
				ELSE @LiveCasinoCommission END
				)
			,@LiveCasinoQualifiedMember = (CASE 
				WHEN @LiveCasino = ProductID THEN TotalQM
				ELSE @LiveCasinoQualifiedMember END
				)
			,@RNGCasinoAmount = (CASE 
				WHEN @RNGCasino = ProductID THEN Amount
				ELSE @RNGCasinoAmount END
				)
			,@RNGCasinoCommission = (CASE 
				WHEN @RNGCasino = ProductID THEN commission
				ELSE @RNGCasinoCommission END
				)
			,@RNGCasinoQualifiedMember = (CASE 
				WHEN @RNGCasino = ProductID THEN TotalQM
				ELSE @RNGCasinoQualifiedMember END
				)
		FROM [dbo].[Aff_CommissionForCurrentMonth](@AffId)

		SELECT @Amount = isnull(@SportsbookAmount, 0) + isnull(@NumberGameAmount, 0) + isnull(@LiveCasinoAmount, 0) + isnull(@RNGCasinoAmount, 0)

		SELECT @GroupId = cg.GroupId
			,@GroupName = cg.GroupName
		FROM @Result r
			INNER JOIN AffInfo AI WITH (NOLOCK)
			ON r.AffId = AI.AffID
			INNER JOIN CommGroup cg WITH (NOLOCK)
			ON AI.GroupID = cg.GroupID
		WHERE r.AffID = @AffId

		UPDATE r
		SET GroupName = @GroupName
			,r.GroupId = @GroupId
			,CashbackPercent = isnull(tmp.DeductedPercentage, 0)
			,CashbackAmount = isnull(tmp.CashAmount, 0)
			,CashbackAmountBase = isnull(tmp.CashAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,Commission = isnull(@Amount, 0) - [dbo].[Aff_GetAffDeductionAll](@AffID, @CurrentDate) --All Product
			,CommissionBase = isnull((@Amount - isnull((tmp.DeductedPercentage * tmp.CashAmount), 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,SportsbookCommission = isnull(@SportsbookAmount, 0)
			,SportsbookQM = isnull(@SportsbookQualifiedMember, 0)
			,SportsbookCommissionPercent = isnull(@SportsbookCommission, 0)
			,SportsbookCommissionBase = isnull(@SportsbookAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,NumberGameCommission = isnull(@NumberGameAmount, 0)
			,NumberGameQM = isnull(@NumberGameQualifiedMember, 0)
			,NumberGameCommissionPercent = isnull(@NumberGameCommission, 0)
			,NumberGameCommissionBase = isnull(@NumberGameAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,LiveCasinoCommission = isnull(@LiveCasinoAmount, 0)
			,LiveCasinoQM = isnull(@LiveCasinoQualifiedMember, 0)
			,LiveCasinoCommissionPercent = isnull(@LiveCasinoCommission, 0)
			,LiveCasinoCommissionBase = isnull(@LiveCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,RNGCasinoCommission = isnull(@RNGCasinoAmount, 0)
			,RNGCasinoQM = isnull(@RNGCasinoQualifiedMember, 0)
			,RNGCasinoCommissionPercent = isnull(@RNGCasinoCommission, 0)
			,RNGCasinoCommissionBase = isnull(@RNGCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,EnableCashback = isnull(tmp.DeductedPercentage, 0)
		FROM @Result r
			LEFT JOIN (
			SELECT TOP(1) 
				@AffId AS AffId
				, b.GroupID
				, b.DeductedPercentage
				, a.Amount AS CashAmount
			FROM DeductionSetting b WITH (NOLOCK)
				INNER JOIN DeductionType c WITH (NOLOCK)
				ON b.DeductionID = c.DTypeID
				LEFT JOIN AffDeductionTransaction a WITH (NOLOCK)
				ON (c.DTypeID = a.DTypeID AND (datediff(m, a.MonthDate, @CurrentDate) = 0) AND AffID = @AffId)
			WHERE c.[DTypeName] = 'Cashback'
				AND b.GroupID = @GroupId
			) tmp
			ON r.AffId = tmp.AffId
		WHERE r.AffID = @AffId
			AND DATEDIFF(m, @CurrentDate, WinlostDate) = 0

		--LEFT JOIN AffDeductionTransaction a with (nolock) on r.AffId = a.AffID and datediff(m, a.MonthDate, @CurrentDate) = 0 and a.ProductID = 0 and a.DTypeID=5
		--LEFT JOIN DeductionSetting d with (nolock)  on d.DeductionID=a.DTypeID  and d.GroupID = @GroupId
		--Get next AffID
		SELECT TOP (1) @AffId = AffID
			,@ExchangeId = ExchangeId
		FROM @Result
		WHERE Commission IS NULL
			AND DATEDIFF(m, @CurrentDate, WinlostDate) = 0

		SET @count = @count + 1

		--reset value
		SELECT @SportsbookAmount = 0
			,@SportsbookCommission = 0
			,@SportsbookQualifiedMember = 0
			,@NumberGameAmount = 0
			,@NumberGameCommission = 0
			,@NumberGameQualifiedMember = 0
			,@LiveCasinoAmount = 0
			,@LiveCasinoCommission = 0
			,@LiveCasinoQualifiedMember = 0
			,@RNGCasinoAmount = 0
			,@RNGCasinoCommission = 0
			,@RNGCasinoQualifiedMember = 0;
	END

	-------Return Data------------
	-- Determine the order direction.
	DECLARE @Direction INT

	SET @Direction = (CASE @SortBy
			WHEN 0 THEN 1
			ELSE - 1 END
			);

	WITH ResTable
	AS (
		SELECT *
			,ROW_NUMBER() OVER (
				ORDER BY CASE @SortBy
						WHEN 0 THEN AffID
						END ASC
					,CASE 
						WHEN @SortBy = 1 THEN CommissionBase
						END DESC
					,AffID ASC
				) AS RowNo
		FROM @Result
		)
	SELECT *
	FROM ResTable
	ORDER BY RowNo
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommissionSettle] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommissionSettle] TO [vnteam] AS [dbo]
