ALTER PROCEDURE [dbo].[Aff_StatementHistorySel] 
	@AffId INT
	,@TransType INT = - 1
	,@FDate SMALLDATETIME = NULL
	,@TDate SMALLDATETIME = NULL
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*
	Created: 20090901@Peter  
	Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)  
	DB: DB052.Affiliate_12BET  
	Original: [Aff_CustomerSelStatementHistory]    

	Revisions:     

	Param's Explanation:    
		• @AffID : Affiliate custid    
		• @TransType :   
			+ 201 : Monthly Winlost  
			+ 202 : Payment Request  
			+ 203 : Adjustment    
			+ -1 : Get all   
		• @FDate : search From date (null: get all)  
		• @TDate : search To date    (null: get all)  
		• @PageSize : Size of page  
		• @PageIndex : current page  
		• @TotalPages : number of pages  
		• @NRows : number of rows  
*/
BEGIN
	SET NOCOUNT ON

	IF (
			@FDate IS NOT NULL
			AND @TDate IS NOT NULL
			AND @FDate > @TDate
			) RETURN

	IF (@TDate > current_timestamp)
		SELECT @TDate = current_timestamp

	IF @FDate IS NOT NULL
		SET @FDate = dbo.Aff_GetStartDate(@FDate)

	IF @TDate IS NOT NULL
		SET @TDate = dbo.Aff_GetEndDate(@TDate)

	DECLARE @AffTrans TABLE (
		TransId BIGINT
		,MonthDate SMALLDATETIME
		,TransType INT
		,Amount MONEY
		,STATUS VARCHAR(20)
		,Creator NVARCHAR(50)
		,Description VARCHAR(200)
		)
	DECLARE @Month INT
		,@Year INT
		,@Currentdate DATETIME
		,@NetPercentReceived FLOAT

	SELECT @NetPercentReceived = 1.0
		,@CurrentDate = current_timestamp

	INSERT INTO @AffTrans
	SELECT 0 AS TransID
		,current_timestamp AS MonthDate
		,0 AS TransType
		,sum(isnull(Amount, 0)) * @NetPercentReceived AS Amount
		,'Current' AS STATUS
		,'' AS Creator
		,'Current Month Statistics' AS Description
	FROM Aff_CommissionForCurrentMonth(@AffID)

	--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc  
	IF (
			NOT EXISTS (
				SELECT (1)
				FROM AffCommission WITH (NOLOCK)
				WHERE AffID = @AffID
					AND datediff(m, winlostdate, dateadd(m, - 1, @CurrentDate)) = 0
				)
			AND datediff(m, (
					SELECT ApprovedDate
					FROM AffInfo WITH (NOLOCK)
					WHERE AffID = @AffID
					), @CurrentDate) >= 1
			)
	BEGIN
		SELECT @Month = month(dateadd(m, - 1, @CurrentDate))
			,@Year = Year(dateadd(m, - 1, @CurrentDate))

		INSERT INTO @AffTrans
		SELECT 0 AS TransID
			,DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, dateadd(m, - 1, @CurrentDate)) + 1, 0)) AS MonthDate
			,0 AS TransType
			,sum(isnull(Amount, 0)) * @NetPercentReceived AS Amount
			,'Current' AS STATUS
			,'' AS Creator
			,'UnCalculated Month' AS Description
		FROM Aff_CommissionForMonth(@AffID, @Month, @Year)
	END

	INSERT INTO @AffTrans
	SELECT a.TransID
		,a.TransDate AS MonthDate
		,a.TransType
		,(CASE 
			WHEN transtype = 202 THEN abs(a.Amount)
			ELSE a.Amount END
			) AS Amount
		,(CASE 
			WHEN transtype = 201
				OR transtype = 203 THEN 'B/F'
			ELSE a.STATUS END
			) AS STATUS
		,isnull(i.username, 'System') AS Creator
		,(CASE 
			WHEN transtype = 202 THEN ap.AdminDesc
			ELSE a.Description END
			)
	FROM AffTrans a(NOLOCK)
		LEFT JOIN AffPayout ap(NOLOCK)
		ON ap.RefID = a.RefID
		LEFT JOIN Affiliate_User i WITH (NOLOCK)
		ON i.custid = a.Creator
	WHERE a.AffID = @AffID
		AND (CASE 
			WHEN @TransType = - 1
				OR TransType = @TransType THEN 1
			ELSE 0 END
			) = 1
		AND (CASE 
			WHEN (
					@FDate IS NOT NULL
					AND @TDate IS NOT NULL
					AND a.CompletedDate BETWEEN @FDate AND @TDate
					)
				OR @FDate IS NULL
				OR @TDate IS NULL THEN 1
			ELSE 0 END
			) = 1
		AND a.STATUS IN ('pending', 'approved', 'completed')
	ORDER BY (CASE 
			WHEN a.STATUS = 'pending' THEN 1
			ELSE 2 END
			)
		,a.CompletedDate DESC
		,a.TransType DESC
		,a.TransID DESC

	SELECT @NRows = count(*)
	FROM @AffTrans

	--Add more row if the month is completed but not transfer yet  
	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	SELECT TransId
		,MonthDate
		,TransType
		,Amount
		,STATUS
		,Creator
		,Description
	FROM (
		SELECT ROW_NUMBER() OVER (
				ORDER BY MonthDate DESC
				) AS TheCount
			,TransId
			,MonthDate
			,TransType
			,Amount
			,STATUS
			,Creator
			,Description
		FROM @AffTrans
		) m
	WHERE m.TheCount BETWEEN @RowStart AND @RowEnd
END
GO

GRANT EXECUTE ON [dbo].[Aff_StatementHistorySel] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_StatementHistorySel] TO [bodbDownlineNetView]
GO

GRANT EXECUTE ON [dbo].[Aff_StatementHistorySel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_StatementHistorySel] TO [VNTeam]
