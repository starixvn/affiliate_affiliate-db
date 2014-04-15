ALTER PROCEDURE [Aff_AffiliateStatementHistorySel] 
	@AffId INT
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*
	Created: 20091225@Peter  
	Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)  
	DB: DB052.Affiliate_12BET  
	Original: [Aff_AffiliateStatementHistorySel]    
	
	Revisions:  
	   
	Param's Explanation:    
		• @AffID : Affiliate custid    
		• @PageSize : Size of page  
		• @PageIndex : current page  
		• @TotalPages : number of pages  
		• @NRows : number of rows  
*/							
BEGIN
	SET NOCOUNT ON

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
	SELECT TransID
		,a.TransDate AS MonthDate
		,TransType
		,(CASE 
			WHEN transtype = 202 THEN abs(a.Amount)
			ELSE a.Amount END
			) AS Amount
		,(CASE 
			WHEN transtype = 203 THEN 'B/F'
			ELSE a.STATUS END
			) AS STATUS
		,isnull(i.username, 'System') AS Creator
		,CASE 
			WHEN TransType = 203 THEN ''
			ELSE coalesce(p.AffDesc, a.Description)
			END AS Description
	FROM AffTrans a(NOLOCK)
		LEFT JOIN AffPayout p(NOLOCK)
		ON p.RefID = a.RefID
		LEFT JOIN Affiliate_User i WITH (NOLOCK)
		ON i.custid = a.Creator
	WHERE a.AffId = @AffId
		AND TransType IN (202, 203) --202: Payment request and 203 : adjustment  
	
	UNION ALL
	SELECT 0 AS TransId
		,a.MonthDate
		,201 AS TransType
		,isnull(a.Amount, 0) + isnull(b.Amount, 0) AS Amount
		,'B/F'
		,'System'
		,a.Description
	FROM (
		SELECT TransDate AS MonthDate
			,Amount
			,Description
		FROM AffTrans a(NOLOCK)
		WHERE AffId = @AffId
			AND TransType = 201 --201: Monthly Transfer  
		) a
		LEFT JOIN (
		SELECT TransDate AS MonthDate
			,Amount
		FROM AffTrans a(NOLOCK)
		WHERE AffId = @AffId
			AND TransType = 204 --204 : Marketing fee(deduction 20% per Affiliate Net Winlost)  
		) b
		ON a.MonthDate = b.MonthDate

	SELECT @NRows = Count(*)
	FROM @AffTrans

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

GRANT EXECUTE ON [dbo].[Aff_AffiliateStatementHistorySel] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateStatementHistorySel] TO [bodbDownlineNetView]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatementHistorySel] TO [VNTeam]
