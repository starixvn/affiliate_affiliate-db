/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_PlayersDetail_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@BaseCurrency	INT = 0
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20191210@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121971]
		- 20201203@Percy: Return DepositFee, WithdrawalFee columns [RedmineID: #146598]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Treat TO, WL = 0 for P2P Products [RedmineID: #157958]
		- 20210819@Percy: Return FirstDepositDate column [RedmineID: #160406]
		- 20210916@Percy: Change WL to GGR [RedmineID: #161540]
		- 20220629@Malcolm: Support an Affiliate remove player [RedmineID: #173640]
		- 20230523@Sally: Support Currency BDT, USD 72 [RedmineID: #188429]
        - 20250905@Sally: Display new signup players [RedmineID: #237856]

	Param's Explanation:
		- @SortById:	1 = Username
						2 = Registered Date
						3 = Deposit
						4 = Withdrawal
						5 = Turnover
						6 = GGR
						7 = Bonus
						8 = Rebate
						9 = Deposit Fee
					   10 = Withdrawal Fee
					   11 = First Deposit Date
		- @IsSortAsc:	0 = DESC
						1 = ASC
		- @BaseCurrency : Currency of B2C
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @BeginOfMonth SMALLDATETIME, @EndOfMonth SMALLDATETIME
	SELECT  @BeginOfMonth	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @EndOfMonth		= EOMONTH(@BeginOfMonth)

	-- Get basecurrency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	CREATE TABLE #tmpData (
        CustId INT PRIMARY KEY, 
        Deposit MONEY DEFAULT(0), 
        Withdrawal MONEY DEFAULT(0), 
        Turnover MONEY DEFAULT(0), 
        GGR MONEY DEFAULT(0), 
        Bonus MONEY DEFAULT(0), 
        Rebate MONEY DEFAULT(0)
    )

	DECLARE @Products TABLE (ProductId INT, IsStraightSetting BIT)
		
	INSERT INTO @Products (ProductId, IsStraightSetting)
	SELECT DISTINCT dsh.ProductId, 0
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.ProductId > 0
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

	INSERT INTO @Products (ProductId, IsStraightSetting)
	SELECT DISTINCT ssh.ProductId, 1
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON agh.GroupId = ssh.GroupId AND agh.MonthDate = ssh.MonthDate
	WHERE ssh.ProductId > 0
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

	-- Get data
	BEGIN
		INSERT INTO #tmpData (CustId, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate)
		SELECT r.CustId
			,SUM(r.Deposit * e.Rate) AS Deposit
			,SUM(r.Withdrawal * e.Rate) AS Withdrawal
			,SUM(CASE WHEN p.IsStraightSetting = 1 THEN 0 ELSE r.Turnover END * e.Rate) AS Turnover
			,SUM(CASE WHEN p.IsStraightSetting = 1 THEN ISNULL(r.Revenue, 0)
					ELSE -(r.Winloss - ISNULL(r.ProgressiveWin, 0)) - ISNULL(r.ProgressiveBet, 0) END * e.Rate) AS GGR
			,SUM(r.Bonus * e.Rate)
			,SUM(r.Rebate * e.Rate)
		FROM dbo.rptMemberDaily r WITH (NOLOCK)
			LEFT JOIN @Products p ON r.ProductId = p.ProductId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON r.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (r.WinlostDate, ISNULL(t.ExchangeId, r.Currency), @BaseExchangeId) e
		WHERE r.WinlostDate BETWEEN @BeginOfMonth AND @EndOfMonth
			AND r.AffId = @AffId
			AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.CustId = r.CustId AND r.WinlostDate BETWEEN mr.FromDate AND mr.ToDate
			)
		GROUP BY r.CustId

        -- Get new signup players who have no any transaction in the month
		INSERT INTO #tmpData(CustId)
        SELECT m.CustId
        FROM dbo.MemberInfo m WITH (NOLOCK)
        WHERE m.AffId = @AffId
            AND m.RegisteredDate >= @BeginOfMonth 
            AND m.RegisteredDate < DATEADD(DAY, 1, @EndOfMonth)
            AND NOT EXISTS (SELECT 1 FROM #tmpData d WHERE d.CustId = m.CustId)

		SELECT @NRows = COUNT(1) FROM #tmpData
	END

	-- Get Banking Fee
	DECLARE @DepositRate DECIMAL(9, 8) = 0, @DepositAmount MONEY = 0
			,@WithdrawalRate DECIMAL(9, 8) = 0, @WithdrawalAmount MONEY = 0
	
	SELECT  @DepositRate = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @DepositRate END
			,@DepositAmount = CASE WHEN DeductionID = 13 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @DepositAmount END
			,@WithdrawalRate = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE @WithdrawalRate END
			,@WithdrawalAmount = CASE WHEN DeductionID = 14 THEN ISNULL(dsh.DeductedAmount, 0) ELSE @WithdrawalAmount END
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupID = dsh.GroupID AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.DeductionID IN (13, 14)
		AND agh.MonthDate = @EndOfMonth
		AND agh.AffID = @AffId

	SELECT @DepositRate = ISNULL(@DepositRate, 0), @DepositAmount = ISNULL(@DepositAmount, 0)
			,@WithdrawalRate = ISNULL(@WithdrawalRate, 0), @WithdrawalAmount = ISNULL(@WithdrawalAmount, 0)

	IF @BaseCurrency <> 0
	BEGIN
		DECLARE @AffCurrency INT, @Rate FLOAT
		SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'		
		-- Get affcurrency mapping
		DECLARE @AffExchangeId INT = @AffCurrency
		SELECT  @AffExchangeId = tp.ExchangeId
		FROM dbo.TpExchange tp WITH (NOLOCK)
		WHERE tp.TpExchangeId = @AffCurrency

		SELECT  @Rate = Rate FROM dbo.Aff_f_ExchangeRate_Sel(@EndOfMonth, @AffExchangeId, @BaseExchangeId)

		SELECT  @DepositAmount = @DepositAmount * @Rate
				,@WithdrawalAmount = @WithdrawalAmount * @Rate
	END

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT CustId, UserName, RegisteredDate, FirstDepositDate, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, DepositFee, WithdrawalFee
	FROM
	(
		SELECT
			m.CustId
			,m.UserName
			,m.RegisteredDate
			,m.FirstDepositDate
			,d.Deposit
			,d.Withdrawal
			,d.Turnover
			,d.GGR
			,d.Bonus
			,d.Rebate
			,d.Deposit * @DepositRate + @DepositAmount AS DepositFee
			,d.Withdrawal * @WithdrawalRate + @WithdrawalAmount AS WithdrawalFee
			,ROW_NUMBER() OVER(ORDER BY
				 (CASE WHEN @IsSortAsc = 1 AND @SortById =  1 THEN m.UserName			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  2 THEN m.RegisteredDate		END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  3 THEN d.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  4 THEN d.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  5 THEN d.Turnover			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  6 THEN d.GGR				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  7 THEN d.Bonus				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  8 THEN d.Rebate				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById =  9 THEN d.Deposit			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 10 THEN d.Withdrawal			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 11 THEN m.FirstDepositDate	END) ASC

				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  1 THEN m.UserName			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  2 THEN m.RegisteredDate		END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  3 THEN d.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  4 THEN d.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  5 THEN d.Turnover			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  6 THEN d.GGR				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  7 THEN d.Bonus				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  8 THEN d.Rebate				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById =  9 THEN d.Deposit			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 10 THEN d.Withdrawal			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 11 THEN m.FirstDepositDate	END) DESC
			) AS RN
		FROM #tmpData d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
	) r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN

	DROP TABLE #tmpData
END
GO