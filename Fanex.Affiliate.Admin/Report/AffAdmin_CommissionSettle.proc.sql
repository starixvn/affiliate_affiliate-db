ALTER PROCEDURE [dbo].[AffAdmin_CommissionSettle] 
	@UserId INT = 0
	,@AffName NVARCHAR(100) = NULL
	,@AffTypes VARCHAR(100) = NULL
	,@CommGroups VARCHAR(1000) = NULL
	,@PreferLanguages VARCHAR(1000) = NULL
	,@Currencies VARCHAR(100) = NULL
	,@BaseCurrency TINYINT = 0
	,@SortBy TINYINT = 0
	,@ExcludeTest BIT = 1
	,@IsITAdmin BIT = 0
	,@ProductIds VARCHAR(100) = NULL
AS
/*    
Task : Commission Report - Company View     
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:
	- 20140513@Bobby: Add Playtech Casio product
	- 20140519@Bobby: Add filter no data
	- 20140610@Bobby: Add PShare & PWin columns

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
		-- add Playtech Casino product
		,@PlaytechCasinoAmount MONEY
		,@PlaytechCasinoCommission DECIMAL(9, 8)
		,@PlaytechCasinoQualifiedMember DECIMAL

	--Reset todate to ending of date
	SELECT @ToDate = GETDATE()
		,@CurrentDate = CURRENT_TIMESTAMP
		,@PreviousMonth = DATEADD(m, - 1, @CurrentDate)
		,@SystemExchangeId = [dbo].[Aff_GetSystemCurrencyID]()

	SELECT @MaxCalculatedDate = ISNULL(MAX(WinlostDate), @PreviousMonth)
	FROM AffCommission NOLOCK

	SET @FromDate = DATEADD(d, 1, @MaxCalculatedDate);

	-- Get productid
	DECLARE @SportsbookId INT
		,@NumberGame INT
		,@LiveCasino INT
		,@RNGCasino INT
		,@PlaytechCasino INT

	SELECT @SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')
		,@PlaytechCasino = dbo.[Aff_GetProductID]('Playtech Casino')

	DECLARE @ProductFilter AS TABLE (ProductId INT)

	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT Val
		FROM [dbo].[strSplit_key](@ProductIds, ',')
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT ProductId
		FROM dbo.Product WITH (NOLOCK)
	END

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
		-- add Playtech Casino product
		,PlaytechCasinoWinloss MONEY
		,PlaytechCasinoQM INT
		,PlaytechCasinoCommissionPercent DECIMAL(9, 8)
		,PlaytechCasinoCommission MONEY
		,PlaytechCasinoWinlossBase MONEY
		,PlaytechCasinoCommissionBase MONEY
		,PShare MONEY
		,PWin MONEY
		,NetGaming MONEY
		,PShareBase MONEY
		,PWinBase MONEY
		,NetGamingBase MONEY
		,EnableCashback BIT DEFAULT(0)
		)

	----For the month(s) that are not calculated
	INSERT INTO @Result (
		AffId
		,STATUS
		,WinlostDate
		,Username
		,ExchangeId
		,Currency
		,GroupID
		,GroupName
		,SportsbookWinloss
		,SportsbookWinlossBase
		,NumberGameWinloss
		,NumberGameWinlossBase
		,LiveCasinoWinloss
		,LiveCasinoWinlossBase
		,RNGCasinoWinloss
		,RNGCasinoWinlossBase
		,PlaytechCasinoWinloss
		,PlaytechCasinoWinlossBase
		,PShare
		,PShareBase
		,PWin
		,PWinBase
		,NetGaming
		,NetGamingBase
		)
	SELECT ad.AffId
		,t.STATUS
		,DATEADD(m, DATEDIFF(m, 0, Winlostdate), 0) AS WinlostDate
		,t.Username
		,t.ExchangeId
		,t.Currency
		,t.GroupId
		,t.GroupName
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
		-----Playtech Casino
		,SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN ad.MemWinlost_aff
				ELSE 0
				END) AS PlaytechCasinoWinloss
		,SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN MemWinlost
				ELSE 0
				END) AS PlaytechCasinoWinlossBase
		-----PShare,PWin & NetGaming
		,SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN PShare_Aff
				ELSE 0
				END) AS PShare
		,SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN PShare
				ELSE 0
				END) AS PShareBase
		,SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN PWin_Aff
				ELSE 0
				END) AS PWin
		,SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN PWin
				ELSE 0
				END) AS PWinBase
		,-SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN ad.MemWinlost_aff - PShare_Aff
				ELSE 0
				END) AS NetGaming
		,-SUM(CASE 
				WHEN ad.ProductID = @PlaytechCasino THEN ad.MemWinlost - PShare
				ELSE 0
				END) AS NetGamingBase
	FROM AffDailySummary ad WITH (NOLOCK)
		INNER JOIN @ProductFilter p
		ON ad.ProductId = p.ProductId
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
		,DATEADD(m, DATEDIFF(m, 0, Winlostdate), 0)
		,t.Username
		,t.ExchangeId
		,t.Currency
		,t.GroupId
		,t.GroupName

	SELECT @AffectedRows = @@ROWCOUNT --ALL Rows that are not calculated

	--Calculate commission Previous month that is not calculated yet
	IF (DATEDIFF(m, @MaxCalculatedDate, @CurrentDate) >= 2)
	BEGIN
		DECLARE @Month INT
			,@Year INT
			,@ExchangeId INT
			,@MonthDate DATETIME

		WHILE EXISTS (
				SELECT TOP 1 1
				FROM @Result
				WHERE Commission IS NULL
					AND DATEDIFF(m, @PreviousMonth, WinlostDate) = 0
				)
		BEGIN
			SELECT TOP (1) @AffId = AffID
				,@ExchangeId = ExchangeId
				,@MonthDate = Winlostdate
			FROM @Result
			WHERE Commission IS NULL
				AND DATEDIFF(m, @PreviousMonth, WinlostDate) = 0

			SELECT @Month = MONTH(@MonthDate)
				,@Year = YEAR(@MonthDate)

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
				--add Playtech Casino product
				,@PlaytechCasinoAmount = (CASE 
					WHEN @PlaytechCasino = ProductID THEN Amount
					ELSE @PlaytechCasinoAmount END
					)
				,@PlaytechCasinoCommission = (CASE 
					WHEN @PlaytechCasino = ProductID THEN commission
					ELSE @PlaytechCasinoCommission END
					)
				,@PlaytechCasinoQualifiedMember = (CASE 
					WHEN @PlaytechCasino = ProductID THEN TotalQM
					ELSE @PlaytechCasinoQualifiedMember END
					)
			FROM [dbo].[Aff_CommissionForMonth](@AffId, @Month, @Year) ac

			-- calculate @Amount base on product filter
			;WITH ProductAmount
			AS (
				SELECT AffId
					,t.ProductId
					,Amount
				FROM (
					SELECT @AffId AS AffId
						,@SportsbookId AS ProductId
						,@SportsbookAmount AS Amount
					
					UNION
					SELECT @AffId AS AffId
						,@NumberGame AS ProductId
						,@NumberGameAmount AS Amount

					UNION
					SELECT @AffId AS AffId
						,@LiveCasino AS ProductId
						,@LiveCasinoAmount AS Amount
					
					UNION
					SELECT @AffId AS AffId
						,@RNGCasino AS ProductId
						,@RNGCasinoAmount AS Amount
					
					UNION
					SELECT @AffId AS AffId
						,@PlaytechCasino AS ProductId
						,@PlaytechCasinoAmount AS Amount
					) t
					INNER JOIN @ProductFilter p
					ON t.ProductId = p.ProductId
				)
			SELECT @Amount = SUM(ISNULL(Amount, 0))
			FROM ProductAmount a
			GROUP BY a.AffId

			SELECT @GroupId = GroupId
			FROM @Result
			WHERE AffID = @AffId

			UPDATE r
			SET CashbackPercent = ISNULL(tmp.DeductedPercentage, 0)
				,CashbackAmount = ISNULL(tmp.CashAmount, 0)
				,CashbackAmountBase = ISNULL(tmp.CashAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,Commission = ISNULL(@Amount, 0) - [dbo].[Aff_GetAffDeductionAll](@AffID, @PreviousMonth) --All Product
				,CommissionBase = ISNULL((@Amount - ISNULL((tmp.DeductedPercentage * tmp.CashAmount), 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,SportsbookCommission = ISNULL(@SportsbookAmount, 0)
				,SportsbookQM = ISNULL(@SportsbookQualifiedMember, 0)
				,SportsbookCommissionPercent = ISNULL(@SportsbookCommission, 0)
				,SportsbookCommissionBase = ISNULL(@SportsbookAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,NumberGameCommission = ISNULL(@NumberGameAmount, 0)
				,NumberGameQM = ISNULL(@NumberGameQualifiedMember, 0)
				,NumberGameCommissionPercent = ISNULL(@NumberGameCommission, 0)
				,NumberGameCommissionBase = ISNULL(@NumberGameAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,LiveCasinoCommission = ISNULL(@LiveCasinoAmount, 0)
				,LiveCasinoQM = ISNULL(@LiveCasinoQualifiedMember, 0)
				,LiveCasinoCommissionPercent = ISNULL(@LiveCasinoCommission, 0)
				,LiveCasinoCommissionBase = ISNULL(@LiveCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,RNGCasinoCommission = ISNULL(@RNGCasinoAmount, 0)
				,RNGCasinoQM = ISNULL(@RNGCasinoQualifiedMember, 0)
				,RNGCasinoCommissionPercent = ISNULL(@RNGCasinoCommission, 0)
				,RNGCasinoCommissionBase = ISNULL(@RNGCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				--add Playtech Casino product
				,PlaytechCasinoCommission = ISNULL(@PlaytechCasinoAmount, 0)
				,PlaytechCasinoQM = ISNULL(@PlaytechCasinoQualifiedMember, 0)
				,PlaytechCasinoCommissionPercent = ISNULL(@PlaytechCasinoCommission, 0)
				,PlaytechCasinoCommissionBase = ISNULL(@PlaytechCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
				,EnableCashback = ISNULL(tmp.DeductedPercentage, 0)
			FROM @Result r
				LEFT JOIN (
				SELECT a.AffID
					,a.Amount AS CashAmount
					,b.DeductedPercentage
					,a.MonthDate
				FROM AffDeductionTransaction a WITH (NOLOCK)
					INNER JOIN AffGroupHistory ai(NOLOCK)
					ON ai.affid = a.affid
						AND DATEDIFF(m, a.MonthDate, ai.MonthDate) = 0
					JOIN DeductionSettingHistory b WITH (NOLOCK)
					ON a.DTypeID = b.DeductionID
						AND ai.groupid = b.groupid
						AND ai.MonthDate = b.MonthDate
					JOIN DeductionType c WITH (NOLOCK)
					ON b.DeductionID = c.DTypeID
				WHERE c.[DTypeName] = 'Cashback'
					AND DATEDIFF(m, a.MonthDate, @PreviousMonth) = 0
					AND a.ProductID = 0
					AND b.GroupID = @GroupId
				) tmp
				ON r.AffID = tmp.AffID
					AND DATEDIFF(m, r.WinlostDate, tmp.MonthDate) = 0
			WHERE r.AffID = @AffId
				AND DATEDIFF(m, @PreviousMonth, r.WinlostDate) = 0

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
				,@RNGCasinoQualifiedMember = 0
				,@PlaytechCasinoAmount = 0
				,@PlaytechCasinoCommission = 0
				,@PlaytechCasinoQualifiedMember = 0
		END
	END

	--update to current month
	WHILE EXISTS (
			SELECT TOP 1 1
			FROM @Result
			WHERE Commission IS NULL
				AND DATEDIFF(m, @CurrentDate, WinlostDate) = 0
			)
	BEGIN
		SELECT TOP (1) @AffId = AffID
			,@ExchangeId = ExchangeId
		FROM @Result
		WHERE Commission IS NULL
			AND DATEDIFF(m, @CurrentDate, WinlostDate) = 0

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
			--add Playtech Casino product
			,@PlaytechCasinoAmount = (CASE 
				WHEN @PlaytechCasino = ProductID THEN Amount
				ELSE @PlaytechCasinoAmount END
				)
			,@PlaytechCasinoCommission = (CASE 
				WHEN @PlaytechCasino = ProductID THEN commission
				ELSE @PlaytechCasinoCommission END
				)
			,@PlaytechCasinoQualifiedMember = (CASE 
				WHEN @PlaytechCasino = ProductID THEN TotalQM
				ELSE @PlaytechCasinoQualifiedMember END
				)
		FROM [dbo].[Aff_CommissionForCurrentMonth](@AffId) ac

		-- calculate @Amount base on product filter
		;WITH ProductAmount
		AS (
			SELECT AffId
				,t.ProductId
				,Amount
			FROM (
				SELECT @AffId AS AffId
					,@SportsbookId AS ProductId
					,@SportsbookAmount AS Amount
				
				UNION
					SELECT @AffId AS AffId
						,@NumberGame AS ProductId
						,@NumberGameAmount AS Amount

				UNION
				SELECT @AffId AS AffId
					,@LiveCasino AS ProductId
					,@LiveCasinoAmount AS Amount
				
				UNION
				SELECT @AffId AS AffId
					,@RNGCasino AS ProductId
					,@RNGCasinoAmount AS Amount
				
				UNION
				SELECT @AffId AS AffId
					,@PlaytechCasino AS ProductId
					,@PlaytechCasinoAmount AS Amount
				) t
				INNER JOIN @ProductFilter p
				ON t.ProductId = p.ProductId
			)
		SELECT @Amount = SUM(ISNULL(Amount, 0))
		FROM ProductAmount a
		GROUP BY a.AffId

		SELECT @GroupId = r.GroupId
		FROM @Result r
		WHERE r.AffID = @AffId

		UPDATE r
		SET CashbackPercent = ISNULL(tmp.DeductedPercentage, 0)
			,CashbackAmount = ISNULL(tmp.CashAmount, 0)
			,CashbackAmountBase = ISNULL(tmp.CashAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,Commission = ISNULL(@Amount, 0) - [dbo].[Aff_GetAffDeductionAll](@AffID, @CurrentDate) --All Product
			,CommissionBase = ISNULL((@Amount - ISNULL((tmp.DeductedPercentage * tmp.CashAmount), 0)) * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,SportsbookCommission = ISNULL(@SportsbookAmount, 0)
			,SportsbookQM = ISNULL(@SportsbookQualifiedMember, 0)
			,SportsbookCommissionPercent = ISNULL(@SportsbookCommission, 0)
			,SportsbookCommissionBase = ISNULL(@SportsbookAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,NumberGameCommission = ISNULL(@NumberGameAmount, 0)
			,NumberGameQM = ISNULL(@NumberGameQualifiedMember, 0)
			,NumberGameCommissionPercent = ISNULL(@NumberGameCommission, 0)
			,NumberGameCommissionBase = ISNULL(@NumberGameAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,LiveCasinoCommission = ISNULL(@LiveCasinoAmount, 0)
			,LiveCasinoQM = ISNULL(@LiveCasinoQualifiedMember, 0)
			,LiveCasinoCommissionPercent = ISNULL(@LiveCasinoCommission, 0)
			,LiveCasinoCommissionBase = ISNULL(@LiveCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,RNGCasinoCommission = ISNULL(@RNGCasinoAmount, 0)
			,RNGCasinoQM = ISNULL(@RNGCasinoQualifiedMember, 0)
			,RNGCasinoCommissionPercent = ISNULL(@RNGCasinoCommission, 0)
			,RNGCasinoCommissionBase = ISNULL(@RNGCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			--add Playtech Casino product
			,PlaytechCasinoCommission = ISNULL(@PlaytechCasinoAmount, 0)
			,PlaytechCasinoQM = ISNULL(@PlaytechCasinoQualifiedMember, 0)
			,PlaytechCasinoCommissionPercent = ISNULL(@PlaytechCasinoCommission, 0)
			,PlaytechCasinoCommissionBase = ISNULL(@PlaytechCasinoAmount * dbo.Aff_GetExchangeRate(@ExchangeId, @SystemExchangeId, NULL), 0)
			,EnableCashback = ISNULL(tmp.DeductedPercentage, 0)
		FROM @Result r
			LEFT JOIN (
			SELECT TOP (1) @AffId AS AffId
				,b.GroupID
				,b.DeductedPercentage
				,a.Amount AS CashAmount
			FROM DeductionSetting b WITH (NOLOCK)
				INNER JOIN DeductionType c WITH (NOLOCK)
				ON b.DeductionID = c.DTypeID
				LEFT JOIN AffDeductionTransaction a WITH (NOLOCK)
				ON (
						c.DTypeID = a.DTypeID
						AND (DATEDIFF(m, a.MonthDate, @CurrentDate) = 0)
						AND AffID = @AffId
						)
			WHERE c.[DTypeName] = 'Cashback'
				AND b.GroupID = @GroupId
			) tmp
			ON r.AffId = tmp.AffId
		WHERE r.AffID = @AffId
			AND DATEDIFF(m, @CurrentDate, WinlostDate) = 0

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
			,@RNGCasinoQualifiedMember = 0
			,@PlaytechCasinoAmount = 0
			,@PlaytechCasinoCommission = 0
			,@PlaytechCasinoQualifiedMember = 0
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
