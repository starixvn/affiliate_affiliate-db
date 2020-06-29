/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
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
	DB: DBAFFN88-Affiliate_N88
	Task: User site - Home - Account Overview - Detail

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121971]

	Param's Explanation:
		- @SortById:	1 = Username
						2 = Registered Date
						3 = Deposit
						4 = Withdrawal
						5 = Turnover
						6 = Winloss
						7 = Bonus
						8 = Banking Fee
		- @IsSortAsc:	0 = DESC
						1 = ASC
*/

BEGIN
	SET NOCOUNT ON

	-- date range for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToEndMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToEndMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @FromBeginMonth))

	CREATE TABLE #tmpData (CustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, Winloss MONEY, Bonus MONEY)

	-- rptMemberDaily
	BEGIN
		;WITH CTE_WinlostDate AS (
			SELECT @FromBeginMonth AS WinlostDate
			UNION ALL
			SELECT DATEADD(DAY, 1, WinlostDate)
			FROM CTE_WinlostDate
			WHERE WinlostDate < @ToEndMonth
		)
		INSERT INTO #tmpData
		(
			CustId
			,Deposit
			,Withdrawal
			,Turnover
			,Winloss
			,Bonus
		)
		SELECT
			r.CustId
			,SUM(r.Deposit * ISNULL(r.Rate, 1))
			,SUM(r.Withdrawal * ISNULL(r.Rate, 1))
			,SUM(r.Turnover * ISNULL(r.Rate, 1))
			,SUM(r.Winloss * ISNULL(r.Rate, 1))
			,SUM(r.Bonus * ISNULL(r.Rate, 1))
		FROM CTE_WinlostDate wld
			CROSS APPLY (
				SELECT r.CustId, r.Deposit, r.Withdrawal, r.Turnover, r.Winloss, r.Bonus, e.Rate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel (r.WinlostDate, r.Currency, @BaseCurrency) e
				WHERE wld.WinlostDate = r.WinlostDate
					AND r.AffId = @AffId
			) r
		GROUP BY r.CustId
		HAVING SUM((r.Deposit + r.Withdrawal + r.Turnover + ABS(r.Winloss) + r.Bonus) * r.Rate) > 0.0
		OPTION (MAXRECURSION 0)
	END

	SELECT @NRows = COUNT(1) FROM #tmpData

	IF @NRows = 0
		RETURN

	DECLARE @BankingFee DECIMAL(9, 8) = 0
	SELECT  @BankingFee = ISNULL(dsh.DeductedPercentage, 0)
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupID = dsh.GroupID AND agh.MonthDate = dsh.MonthDate
	WHERE dsh.DeductionID = 12 AND agh.MonthDate = @ToEndMonth
		AND agh.AffID = @AffId

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT CustId, UserName, RegisteredDate, Deposit, Withdrawal, Turnover, Winloss, Bonus, BankingFee
	FROM
	(
		SELECT
			m.CustId
			,m.UserName
			,m.RegisteredDate
			,d.Deposit
			,d.Withdrawal
			,d.Turnover
			,d.Winloss
			,d.Bonus
			,(d.Deposit + d.Withdrawal) * @BankingFee AS BankingFee
			,ROW_NUMBER() OVER(ORDER BY
				 (CASE WHEN @IsSortAsc = 1 AND @SortById = 1 THEN m.UserName				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 2 THEN m.RegisteredDate			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 3 THEN d.Deposit					END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 4 THEN d.Withdrawal				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 5 THEN d.Turnover				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 6 THEN d.Winloss					END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 7 THEN d.Bonus					END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 8 THEN d.Deposit + d.Withdrawal	END) ASC
				
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 1 THEN m.UserName				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 2 THEN m.RegisteredDate			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 3 THEN d.Deposit					END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 4 THEN d.Withdrawal				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 5 THEN d.Turnover				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 6 THEN d.Winloss					END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 7 THEN d.Bonus					END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 8 THEN d.Deposit + d.Withdrawal	END) DESC
			) AS RN
		FROM #tmpData d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.CustId = m.CustId
		WHERE NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= @ToEndMonth
					AND mr.CustId = d.CustId
				)
	) r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN

	DROP TABLE #tmpData
END
GO