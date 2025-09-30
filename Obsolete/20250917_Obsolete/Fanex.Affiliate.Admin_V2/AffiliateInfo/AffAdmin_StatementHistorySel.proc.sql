/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

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
	Task: Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)  
	DB:   
	Original: [Aff_CustomerSelStatementHistory]
  
	Revisions:     
		- 20131126@Johnny: Fix filter by transaction type and status
		- 20140520@Bobby: check data existing in MemberDaily for previous month
		- 20140703@Bobby: check data existing in AffCommission
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180208@Alex  : Support Liecnsee admin portal #90545

	Param's Explanation:    
		• @AffID: Affiliate custid    
		• @TransType:   
					 + 201: Monthly Winlost  
					 + 202: Payment Request  
					 + 203: Adjustment    
					 +  -1: Get all   
		• @FromDate: search From date (null: get all)
		• @ToDate: search To date (null: get all)
*/

BEGIN
	SET NOCOUNT ON

	IF (
			@FromDate IS NOT NULL
			AND @ToDate IS NOT NULL
			AND @FromDate > @ToDate
			) RETURN

	IF (@ToDate > current_timestamp)
		SELECT @ToDate = current_timestamp

	IF @FromDate IS NOT NULL
		SET @FromDate = dbo.Aff_GetStartDate(@FromDate)

	IF @ToDate IS NOT NULL
		SET @ToDate = dbo.Aff_GetEndDate(@ToDate)

	DECLARE @AffCurrency SMALLINT
		,@SystemCurrency SMALLINT
		,@MonthlyTransferType INT
		,@PaymentType INT
		,@AdjustmentType INT

	SELECT @MonthlyTransferType = 201
		,@PaymentType = 202
		,@AdjustmentType = 203

	DECLARE @TransStatusTable TABLE (TransStatus VARCHAR(20))

	INSERT INTO @TransStatusTable
	SELECT CAST(val AS VARCHAR(20))
	FROM [dbo].[strSplit](@Status, ',')

	DECLARE @TransTypeTable TABLE (TransType VARCHAR(20))

	INSERT INTO @TransTypeTable
	SELECT CAST(val AS VARCHAR(20))
	FROM [dbo].[strSplit](@TransType, ',')

	--Convert aff currency to system currency
	SELECT @SystemCurrency = CurrencyId
	FROM Currency(NOLOCK)
	WHERE CurrencyCode = (
			SELECT TOP 1 SValue
			FROM SystemSettings NOLOCK
			WHERE SName = 'SystemCurrency'
				AND Type = 'Meta'
			)

	SELECT @AffCurrency = Currency
	FROM AffInfo(NOLOCK)
	WHERE AffID = @AffId

	DECLARE @AffTrans TABLE
	(
		TransId BIGINT
		,TransDate SMALLDATETIME
		,CompletedDate SMALLDATETIME
		,TransType INT
		,Amount MONEY
		,STATUS VARCHAR(20)
		,Creator NVARCHAR(50)
		,Description NVARCHAR(300)
	)
	
	DECLARE @Month INT
		,@Year INT
		,@Amount MONEY
		,@Currentdate DATETIME
		,@NetPercentReceived FLOAT

	SELECT @NetPercentReceived = 1.0
		,@CurrentDate = current_timestamp

	IF (
		(@TransType IS NULL OR @MonthlyTransferType IN (SELECT TransType FROM @TransTypeTable))
		AND (@DateOption = 0 OR @Currentdate BETWEEN @FromDate AND @ToDate)
	)
	BEGIN
		EXEC [dbo].[Aff_CalMonthlyEarningCurrent]
			@AffID = @AffID
			,@Amount = @Amount OUTPUT

		INSERT INTO @AffTrans
		SELECT 0 AS TransID
			,current_timestamp AS TransDate
			,NULL AS CompletedDate
			,@MonthlyTransferType AS TransType
			,isnull(@Amount, 0) * @NetPercentReceived AS Amount
			,'Processing' AS STATUS
			,'' AS Creator
			,'Current month statistics' AS Description
	END

	--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc  
	IF (
			(
				@TransType IS NULL
				OR @MonthlyTransferType IN (
					SELECT *
					FROM @TransTypeTable
				)
			)
			AND (
				NOT EXISTS(SELECT TOP 1 1 FROM AffCommission ac(NOLOCK) WHERE ac.AffID = @AffID AND DATEDIFF(MONTH, winlostdate, DATEADD(MONTH, -1, @CurrentDate)) = 0)	
			)
			AND (
				@DateOption = 0
				OR dateadd(m, - 1, @CurrentDate) BETWEEN @FromDate AND @ToDate
			)
			-- check data existing in MemberDaily
			AND EXISTS (
					SELECT TOP 1 1
					FROM dbo.MemberDaily m (NOLOCK)
						INNER JOIN (
							SELECT sg.ProductId 
							FROM AffGroupHistory ag (NOLOCK)
								INNER JOIN GroupSettingHistory sg (NOLOCK) ON ag.GroupId = sg.GroupId AND ag.MonthDate = sg.MonthDate
							WHERE ag.AffId = @AffId AND ag.MonthDate = CAST(dbo.Aff_GetLastDayOfMonth(DATEADD(m, - 1, @CurrentDate)) AS DATE)
						) g ON m.ProductId = g.ProductId
					WHERE AffId = @AffId
						AND Winlostdate BETWEEN dbo.Aff_GetFirstDayOfMonth(DATEADD(m, - 1, @CurrentDate)) AND dbo.Aff_GetLastDayOfMonth(DATEADD(m, - 1, @CurrentDate))
					)
			)
	BEGIN
		SELECT @Month = month(dateadd(m, - 1, @CurrentDate))
			,@Year = Year(dateadd(m, - 1, @CurrentDate))

		EXEC [dbo].[Aff_CalMonthlyEarning]
			@AffID = @AffID
			,@Month = @Month
			,@Year = @Year
			,@Amount = @Amount OUTPUT

		INSERT INTO @AffTrans
		SELECT 0 AS TransID
			,DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, dateadd(m, - 1, @CurrentDate)) + 1, 0)) AS TransDate
			,NULL AS CompletedDate
			,@MonthlyTransferType AS TransType
			,isnull(@Amount, 0) * @NetPercentReceived AS Amount
			,'Processing' AS STATUS
			,'' AS Creator
			,'Waiting for settlement' AS Description
	END

	INSERT INTO @AffTrans
	SELECT a.TransID
		,a.TransDate
		,a.CompletedDate
		,a.TransType
		,(CASE 
			WHEN transtype = @PaymentType THEN abs(a.Amount)
			ELSE a.Amount END
			) AS Amount
		,(CASE 
			WHEN transtype = @MonthlyTransferType OR transtype = @AdjustmentType THEN 'B/F'
			WHEN a.STATUS = 'Pending' THEN 'Processing'
			WHEN a.STATUS = 'Completed' THEN 'Approved'
			ELSE a.STATUS END
			) AS STATUS
		,CASE
			WHEN a.Status IN ('Pending', 'Cancelled') AND a.TransType = 202 THEN ai.UserName
			WHEN a.TransType = 201 THEN 'System'
			ELSE a.AdminUserName END AS Creator
		,(CASE 
			WHEN transtype = @PaymentType THEN ap.AdminDesc
			ELSE a.Description END
			)
	FROM AffTrans a(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON a.AffID = ai.AffID
		LEFT JOIN AffPayout ap(NOLOCK) ON ap.RefID = a.RefID
		
	WHERE a.AffID = @AffID
	ORDER BY (CASE 
			WHEN a.STATUS = 'pending'
				OR a.STATUS = 'Processing' THEN 1
			ELSE 2 END
			)
		,a.CompletedDate DESC
		,a.TransType DESC
		,a.TransID DESC

	SELECT TransId
		,TransDate
		,CompletedDate
		,TransType
		,CASE @BaseCurrency
			WHEN 0 THEN Amount
			ELSE Amount * dbo.Aff_GetExchangeRate(@AffCurrency, @SystemCurrency, NULL)
			END AS Amount
		,STATUS
		,Creator
		,Description
	FROM @AffTrans AS a
	WHERE (
			@DateOption = 0
			OR (
				@DateOption = 1
				AND a.TransDate BETWEEN @FromDate AND @ToDate
			)
			OR (
				@DateOption = 2
				AND a.CompletedDate BETWEEN @FromDate AND @ToDate
			)
		)
		AND (
			@TransType IS NULL
			OR a.TransType IN (SELECT TransType FROM @TransTypeTable)
		)
		AND a.STATUS IN (SELECT TransStatus FROM @TransStatusTable)
	ORDER BY TransDate DESC
		,TransType DESC
		,transID ASC
END
GO