/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_StatementHistorySel] 
	@AffId INT
	,@TransType VARCHAR(100) = NULL
	,@Status VARCHAR(100) = NULL
	,@DateOption TINYINT = 0
	,@FromDate SMALLDATETIME = NULL
	,@ToDate SMALLDATETIME = NULL
	,@BaseCurrency INT = 0
AS

/*
	Created: 20090901@Peter
	DB: DBAFF-Affiliate_Athena000
	Task: Admin - Statement history
	
	Revisions:
		- 20131126@Johnny: Fix filter by transaction type and status
		- 20140520@Bobby: check data existing in MemberDaily for previous month
		- 20140703@Bobby: check data existing in AffCommission
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180208@Alex  : Support Liecnsee admin portal #90545
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]

	Param's Explanation:    
		• @AffID: Affiliate custid    
		• @TransType:   
					 + 201: Monthly Winlost  
					 + 202: Payment Request  
					 + 203: Adjustment    
		• @FromDate: search From date (null: get all)
		• @ToDate: search To date (null: get all)
*/

BEGIN
	SET NOCOUNT ON

	IF @DateOption = 0 OR @FromDate IS NULL OR @ToDate IS NULL -- get all
		SELECT @FromDate = ApprovedDate, @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0)) -- last day of current month
		FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

	SELECT @FromDate = CONVERT(DATE, @FromDate), @ToDate = CONVERT(DATE, @ToDate)

	IF @TransType IS NULL
		SELECT @TransType = COALESCE(@TransType + ',', '') + CONVERT(VARCHAR(15), TypeId) FROM dbo.TransType WITH (NOLOCK)
	
	DECLARE @AffCurrency SMALLINT, @SystemCurrency SMALLINT, @UserName VARCHAR(30)
	SELECT  @AffCurrency = Currency, @UserName = UserName FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId
	SELECT  @SystemCurrency = CurrencyId FROM dbo.Currency WITH (NOLOCK)
	WHERE CurrencyCode IN (SELECT SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'SystemCurrency' AND Type = 'Meta')
	
	DECLARE @AffTrans TABLE
	(
		TransId			BIGINT
		,TransDate		SMALLDATETIME
		,CompletedDate	SMALLDATETIME
		,TransType		INT
		,Amount			MONEY
		,Status			VARCHAR(20)
		,Creator		NVARCHAR(50)
		,Description	NVARCHAR(300)
	)

	-- Calculated months
	INSERT INTO @AffTrans (TransId, TransDate, CompletedDate, TransType, Amount, Status, Creator, Description)
	SELECT at.TransId, at.TransDate, at.CompletedDate, at.TransType
		,CASE WHEN at.TransType = 202 THEN ABS(at.Amount) ELSE at.Amount END AS Amount
		,CASE
			WHEN at.TransType IN (201, 203) THEN 'B/F'
			WHEN at.Status = 'Pending' THEN 'Processing'
			WHEN at.Status = 'Completed' THEN 'Approved'
			ELSE at.Status
		END AS Status
		,CASE
			WHEN at.TransType = 201 THEN 'System'
			WHEN at.TransType = 202 AND at.Status IN ('Pending', 'Cancelled') THEN @UserName
			ELSE at.AdminUserName
		END AS Creator
		,CASE WHEN at.TransType = 202 THEN ap.AdminDesc ELSE at.Description END AS Description
	FROM dbo.AffTrans at WITH (NOLOCK)
		LEFT JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefId = ap.RefId
	WHERE at.AffId = @AffId
		AND 1 = CASE
					WHEN @DateOption = 0 THEN 1 -- get all
					WHEN @DateOption = 1 AND at.TransDate >= @FromDate AND at.TransDate < DATEADD(DAY, 1, @ToDate) THEN 1
					WHEN @DateOption = 2 AND at.CompletedDate >= @FromDate AND at.CompletedDate < DATEADD(DAY, 1, @ToDate) THEN 1
					ELSE 0
				END
		AND ',' + @TransType + ',' LIKE '%,' + CONVERT(VARCHAR(15), at.TransType) + ',%'

	DELETE @AffTrans WHERE ',' + @Status + ',' LIKE '%,' + Status + ',%'

	-- Uncalculated months
	IF @DateOption IN (0, 1)
		AND ',' + @TransType + ',' LIKE '%,201,%'
		AND ',' + @Status + ',' LIKE '%,Processing,%'
	BEGIN
		SELECT @FromDate = ISNULL(DATEADD(DAY, 1, MAX(WinlostDate)), @FromDate) FROM dbo.AffCommission WITH (NOLOCK) WHERE AffId = @AffId

		DECLARE @AffMonthlyEarning TABLE (MonthDate SMALLDATETIME, Amount MONEY)
		INSERT INTO @AffMonthlyEarning (MonthDate, Amount)
		EXEC dbo.Aff_MonthlyEarning @AffId = @AffId, @FromDate = @FromDate, @ToDate = @ToDate

		INSERT INTO @AffTrans (TransId, TransDate, CompletedDate, TransType, Amount, Status, Creator, Description)
		SELECT 0 AS TransId
			,CASE WHEN DATEDIFF(MONTH, MonthDate, GETDATE()) = 0 THEN GETDATE() ELSE MonthDate END AS TransDate
			,NULL AS CompletedDate, 201 AS TransType, Amount * 0.1 AS Amount, 'Processing' AS Status, '' AS Creator
			,CASE WHEN DATEDIFF(MONTH, MonthDate, GETDATE()) = 0 THEN 'Current month statistics' ELSE 'Waiting for settlement' END AS Description
		FROM @AffMonthlyEarning
		WHERE 1 = CASE
					WHEN @DateOption = 0 THEN 1 -- get all
					WHEN DATEDIFF(MONTH, MonthDate, GETDATE()) = 0 AND CONVERT(DATE, GETDATE()) BETWEEN @FromDate AND @ToDate THEN 1
					WHEN MonthDate >= @FromDate AND MonthDate < DATEADD(DAY, 1, @ToDate) THEN 1
					ELSE 0
				END
	END

	-- Return data
	DECLARE @ExRate FLOAT = 1
	IF @BaseCurrency <> 0
		SELECT @ExRate = dbo.Aff_GetExchangeRate(@AffCurrency, @SystemCurrency, NULL)
	
	SELECT TransId, TransDate, CompletedDate, TransType, Amount * @ExRate AS Amount, Status, Creator, Description
	FROM @AffTrans
	ORDER BY TransDate DESC, TransType DESC, TransID ASC
END
GO