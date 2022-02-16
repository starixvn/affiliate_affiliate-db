/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffiliateStatementHistorySel]  
	@AffId		INT,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@TotalPages INT = 0 OUTPUT,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20091225@Peter
	DB: DBAFF-Affiliate_Athena000
	Task: User - Statement history

	Revisions:  	
		+ 20130813@Don: Fixed bug [Statement history - Data in Satement history table is not ordered] (redmine.nexcel.vn/issues/4327)
		- 20180208@Alex  : Support Liecnsee admin portal #90545
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]

	Param's Explanation:  
		• @AffID: Affiliate custid  
		• @PageSize: Size of page
		• @PageIndex: current page
		• @TotalPages: number of pages
		• @NRows: number of rows
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffTrans TABLE
	(
		TransId			BIGINT
		,MonthDate		SMALLDATETIME
		,TransType		INT
		,Amount			MONEY
		,Status			VARCHAR(20)
		,Creator		NVARCHAR(50)
		,Description	NVARCHAR(300)
	)

	DECLARE @UserName VARCHAR(30)
	SELECT  @UserName = UserName FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

	-- Calculated months
	INSERT INTO @AffTrans (TransId, MonthDate, TransType, Amount, Status, Creator, Description)
	SELECT CASE WHEN at.TransType = 201 THEN 0 ELSE at.TransId END AS TransId
		,at.TransDate, at.TransType
		,CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END AS Amount
		,CASE WHEN at.TransType IN (201, 203) THEN 'B/F' ELSE at.Status END AS Status
		,CASE
			WHEN at.TransType = 201 THEN 'System'
			WHEN at.TransType = 202 AND at.Status IN ('Pending', 'Cancelled') THEN @UserName
			ELSE at.AdminUserName
		END AS Creator
		,CASE
			WHEN at.TransType = 202 THEN ISNULL(ap.AffDesc, at.Description)
			WHEN at.TransType = 203 THEN ''
			ELSE at.Description
		END AS Description
	FROM dbo.AffTrans at WITH (NOLOCK)
		LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefId = ap.RefId
	WHERE at.AffId = @AffId

	-- Uncalculated months
	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
	SELECT @FromDate = ApprovedDate, @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0)) -- last day of current month
	FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

	SELECT @FromDate = ISNULL(DATEADD(DAY, 1, MAX(WinlostDate)), @FromDate) FROM dbo.AffCommission WITH (NOLOCK) WHERE AffId = @AffId

	DECLARE @AffMonthlyEarning TABLE (MonthDate SMALLDATETIME, Amount MONEY)
	INSERT INTO @AffMonthlyEarning (MonthDate, Amount)
	EXEC dbo.Aff_MonthlyEarning @AffId = @AffId, @FromDate = @FromDate, @ToDate = @ToDate

	INSERT INTO @AffTrans (TransId, MonthDate, TransType, Amount, Status, Creator, Description)
	SELECT 0 AS TransId
		,CASE WHEN DATEDIFF(MONTH, MonthDate, GETDATE()) = 0 THEN GETDATE() ELSE MonthDate END AS MonthDate
		,0 AS TransType
		,Amount * 0.1 AS Amount
		,'Current' AS Status
		,'' AS Creator
		,CASE WHEN DATEDIFF(MONTH, MonthDate, GETDATE()) = 0 THEN 'Current Month Statistics' ELSE 'UnCalculated Month' END AS Description
	FROM @AffMonthlyEarning

	-- Retunr data
	SELECT @NRows = COUNT(1) FROM @AffTrans
	SELECT @TotalPages = @NRows / @PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1
	SELECT  @RowEnd = @RowStart + @PageSize - 1

	SELECT TransId, MonthDate, TransType, Amount, Status, Creator, Description
	FROM (
		SELECT TransId, MonthDate, TransType, Amount, Status, Creator, Description
			,ROW_NUMBER() OVER(ORDER BY MonthDate DESC) AS RN
		FROM @AffTrans
	) m
	WHERE RN BETWEEN @RowStart AND @RowEnd
	ORDER BY RN
END
GO