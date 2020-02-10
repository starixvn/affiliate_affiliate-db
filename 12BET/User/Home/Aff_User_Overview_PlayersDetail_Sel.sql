/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Overview_PlayersDetail_Sel]
	@AffId			INT
	,@MonthDate		SMALLDATETIME
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20191210@Percy
	DB: DBAFF12BET.Affiliate_12BET
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

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'
	
	-- date range for get data whole month of @MonthDate
	DECLARE @FromBeginMonth SMALLDATETIME, @ToEndMonth SMALLDATETIME
	SELECT  @FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @ToEndMonth		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @FromBeginMonth))

	CREATE TABLE #tmpData (IBCCustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, Winloss MONEY, Bonus MONEY)

	-- rptMemberDaily
	IF @ToEndMonth > @CutOffDate
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
			IBCCustId
			,Deposit
			,Withdrawal
			,Turnover
			,Winloss
			,Bonus
		)
		SELECT
			r.IBCCustId
			,SUM(r.Deposit * r.AffExRate)
			,SUM(r.Withdrawal * r.AffExRate)
			,SUM(r.Turnover * r.AffExRate)
			,SUM(r.Winloss * r.AffExRate)
			,SUM(r.Bonus * r.AffExRate)
		FROM CTE_WinlostDate wld
			CROSS APPLY (
				SELECT r.IBCCustId, r.Deposit, r.Withdrawal, r.Turnover, r.Winloss, r.Bonus, r.AffExRate
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
				WHERE wld.WinlostDate = r.WinlostDate
					AND r.AffId = @AffId
			) r
		GROUP BY r.IBCCustId
		HAVING SUM((r.Deposit + r.Withdrawal + r.Turnover + ABS(r.Winloss) + r.Bonus) * r.AffExRate) > 0.0
		OPTION (MAXRECURSION 0)
	END
	-- MemberDaily
	ELSE
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
			IBCCustId
			,Deposit
			,Withdrawal
			,Turnover
			,Winloss
			,Bonus
		)
		SELECT
			r.IBCCustId
			,SUM(r.Deposit * r.AffExRate)
			,SUM(r.Withdrawal * r.AffExRate)
			,SUM(r.Turnover * r.AffExRate)
			,SUM(r.Winlost * r.AffExRate)
			,SUM(r.Bonus * r.AffExRate)
		FROM CTE_WinlostDate wld
			CROSS APPLY (
				SELECT r.IBCCustId, r.Deposit, r.Withdrawal, r.Turnover, r.Winlost, r.Bonus, r.AffExRate
				FROM dbo.MemberDaily r WITH (NOLOCK)
				WHERE wld.WinlostDate = r.WinlostDate
					AND r.AffId = @AffId
			) r
		GROUP BY r.IBCCustId
		HAVING SUM((r.Deposit + r.Withdrawal + r.Turnover + ABS(r.Winlost) + r.Bonus) * r.AffExRate) > 0.0
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

	SELECT IBCCustId, UserName, RegisteredDate, Deposit, Withdrawal, Turnover, Winloss, Bonus, BankingFee
	FROM
	(
		SELECT
			m.IBCCustId
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
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.IBCCustId = m.IBCCustId
		WHERE NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= @ToEndMonth
					AND mr.IBCCustId = d.IBCCustId
				)
	) r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN

	DROP TABLE #tmpData
END
GO