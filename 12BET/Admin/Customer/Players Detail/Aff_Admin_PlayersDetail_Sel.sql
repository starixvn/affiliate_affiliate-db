/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_PlayersDetail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@FromDate		DATETIME
	,@ToDate		DATETIME
	,@SortById		TINYINT = 5 -- default
	,@IsSortAsc		BIT = 0 -- default
	,@IsExportExcel	BIT = 0
	,@PageIndex		INT = 1
	,@PageSize		INT = 20
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task:
		Admin site - Customer - Players Detail
		Admin site - Customer - Statistics - Click amount of Total Active Players

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Support export excel [RedmineID: #102322]
		- 20191210@Percy: Add withdrawal column and support sort [RedmineID: #121971]
		- 20210223@Percy: Exclude removed member [RedmineID: #149213]
		- 20210528@Malcolm: Filter by date [RedmineID: #149210]
		- 20210528@Malcolm: Add turnover and winlost column[RedmineID: #149210]
	Param's Explanation:
		- @SortById:	1 = Username
						2 = Registered Date
						3 = Deposit
						4 = Withdrawal
						5 = Turnover
						6 = Winloss
						7 = Bonus
						8 = Banking Fee
						9 = IBCUsername
		- @IsSortAsc:	0 = DESC
						1 = ASC
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CutOffDate SMALLDATETIME
	SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'
	
	CREATE TABLE #tmpData (IBCCustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, Winloss MONEY, Bonus MONEY, BankingFee MONEY, EndOfMonth DATETIME)
	-- rptMemberDaily
	IF @ToDate > @CutOffDate
	BEGIN
		;WITH CTE_WinlostDate AS (
			SELECT @FromDate AS WinlostDate
			UNION ALL
			SELECT DATEADD(DAY, 1, WinlostDate)
			FROM CTE_WinlostDate
			WHERE WinlostDate < @ToDate
		)
		INSERT INTO #tmpData
		(
			IBCCustId
			,EndOfMonth
			,Deposit
			,Withdrawal
			,Turnover
			,Winloss
			,Bonus
		)
		SELECT
			r.IBCCustId
			,DATEADD(DAY, - 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, wld.WinlostDate) + 1, 0)) AS EndOfMonth
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
					AND (@ProductId = 0 OR r.ProductId < 0 OR r.ProductId = @ProductId)
			) r
		GROUP BY r.IBCCustId, DATEADD(DAY, - 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, wld.WinlostDate) + 1, 0))
		HAVING SUM((r.Deposit + r.Withdrawal + r.Turnover + ABS(r.Winloss) + r.Bonus) * r.AffExRate) > 0.0
		OPTION (MAXRECURSION 0)
	END
	-- MemberDaily
	ELSE
	BEGIN
		;WITH CTE_WinlostDate AS (
			SELECT @FromDate AS WinlostDate
			UNION ALL
			SELECT DATEADD(DAY, 1, WinlostDate)
			FROM CTE_WinlostDate
			WHERE WinlostDate < @ToDate
		)
		INSERT INTO #tmpData
		(
			IBCCustId
			,EndOfMonth
			,Deposit
			,Withdrawal
			,Turnover
			,Winloss
			,Bonus
		)
		SELECT
			r.IBCCustId
			,DATEADD(DAY, - 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, wld.WinlostDate) + 1, 0)) AS EndOfMonth
			,SUM(r.Deposit * r.AffExRate)
			,SUM(r.Withdrawal * r.AffExRate)
			,SUM(CASE WHEN @ProductId = 0 OR r.SportType = @ProductId THEN r.Turnover * r.AffExRate ELSE 0 END) AS Turnover
			,SUM(CASE WHEN @ProductId = 0 OR r.SportType = @ProductId THEN r.Winlost * r.AffExRate ELSE 0 END) AS Winloss
			,SUM(r.Bonus * r.AffExRate)
		FROM CTE_WinlostDate wld
			CROSS APPLY (
				SELECT r.IBCCustId, r.SportType, r.Deposit, r.Withdrawal, r.Turnover, r.Winlost, r.Bonus, r.AffExRate
				FROM dbo.MemberDaily r WITH (NOLOCK)
				WHERE wld.WinlostDate = r.WinlostDate
					AND r.AffId = @AffId
			) r
		GROUP BY r.IBCCustId, DATEADD(DAY, - 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, wld.WinlostDate) + 1, 0))
		HAVING SUM((r.Deposit + r.Withdrawal + r.Turnover + ABS(r.Winlost) + r.Bonus) * r.AffExRate) > 0.0
		OPTION (MAXRECURSION 0)
	END

	UPDATE t
		SET t.BankingFee = (t.Withdrawal + t.Deposit) * l.DeductedPercentage
	FROM #tmpData t
	OUTER APPLY (
		SELECT ISNULL(dsh.DeductedPercentage, 0) AS DeductedPercentage
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupID = dsh.GroupID AND agh.MonthDate = dsh.MonthDate
		WHERE dsh.DeductionID = 12 AND agh.MonthDate = t.EndOfMonth
			AND agh.AffID = @AffId
	) l

	CREATE TABLE #Result (IBCCustId INT, Deposit MONEY, Withdrawal MONEY, Turnover MONEY, Winloss MONEY, Bonus MONEY, BankingFee MONEY)

	INSERT INTO #Result (IBCCustId, Deposit, Withdrawal, Turnover, Winloss, Bonus, BankingFee)
	SELECT	IBCCustId, SUM(Deposit), SUM(Withdrawal), SUM(Turnover), SUM(Winloss), SUM(Bonus), SUM(BankingFee)
	FROM #tmpData t
	GROUP BY t.IBCCustId

	SELECT @NRows = COUNT(1)
	FROM #tmpData d
		LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON d.IBCCustId = mr.IBCCustId AND mr.MonthDate = @ToDate
	WHERE mr.IBCCustId IS NULL

	IF @NRows = 0
		RETURN

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 0
		SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1
	ELSE
		SELECT @RowStart =  1, @RowEnd = @NRows

	SELECT IBCCustId, UserName, IBCUserName, RegisteredDate, Deposit, Withdrawal, Turnover, Winloss, Bonus, BankingFee
	FROM
	(
		SELECT
			m.IBCCustId
			,m.UserName
			,m.IBCUserName
			,m.RegisteredDate
			,d.Deposit
			,d.Withdrawal
			,d.Turnover
			,d.Winloss
			,d.Bonus
			,d.BankingFee AS BankingFee
			,ROW_NUMBER() OVER(ORDER BY
				 (CASE WHEN @IsSortAsc = 1 AND @SortById = 1 THEN m.UserName				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 2 THEN m.RegisteredDate			END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 3 THEN d.Deposit					END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 4 THEN d.Withdrawal				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 5 THEN d.Turnover				END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 6 THEN d.Winloss					END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 7 THEN d.Bonus					END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 8 THEN d.Deposit + d.Withdrawal	END) ASC
				,(CASE WHEN @IsSortAsc = 1 AND @SortById = 9 THEN m.IBCUserName				END) ASC				
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 1 THEN m.UserName				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 2 THEN m.RegisteredDate			END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 3 THEN d.Deposit					END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 4 THEN d.Withdrawal				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 5 THEN d.Turnover				END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 6 THEN d.Winloss					END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 7 THEN d.Bonus					END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 8 THEN d.Deposit + d.Withdrawal	END) DESC
				,(CASE WHEN @IsSortAsc = 0 AND @SortById = 9 THEN m.IBCUserName				END) DESC
			) AS RN
		FROM #Result d
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON d.IBCCustId = m.IBCCustId
			LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON m.IBCCustId = mr.IBCCustId AND mr.MonthDate = @ToDate
		WHERE mr.IBCCustId IS NULL
	) r
	WHERE r.RN BETWEEN @RowStart AND @RowEnd
	ORDER BY r.RN

	DROP TABLE #tmpData
	DROP TABLE #Result
END
GO