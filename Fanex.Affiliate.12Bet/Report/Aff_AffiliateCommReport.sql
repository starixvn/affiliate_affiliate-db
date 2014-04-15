ALTER PROCEDURE [dbo].[Aff_AffiliateCommReport] 
	@MonthDate DATETIME = NULL
	,@SportId TINYINT = 1
	,@UserName NVARCHAR(50) = NULL
	,@PreferredLanguage VARCHAR(11) = NULL
	,@AffType TINYINT = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*
	Created: @Peter
	Task : Get report of Active members 
	DB: DB052.Affiliate_12BET
	Original: [Aff_AffiliateCommReport]

	Revisions:
		-20120508@Johnny: Add dropdown box for sport type

	Param's Explanation:
		• @Fromdate Time search From
		• @Todate Time search To,
		• @IsGetAll if getall = 1 => get data in all date,
		• @UserName Affiliate username need to search(must match username),
		• @PageSize Page Size,
		• @PageIndex Current page,
		• @TotalPages num pages return,
		• @NRows num rows return
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Todate DATETIME

	SELECT @UserName = '%' + Coalesce(@UserName, '') + '%'

	SELECT @MonthDate = convert(VARCHAR(10), DATEADD(s, - 1, DATEADD(mm, DATEDIFF(m, 0, @MonthDate) + 1, 0)), 120)
		,@ToDate = dateadd(d, - 1, dateadd(m, datediff(m, 0, @MonthDate) + 1, 0)) --Assign todate to last date of month of todate

	DECLARE @SportbookId INT
		,@CasinoId INT

	SELECT @SportbookId = dbo.Aff_GetSportID('SportsBook')
		,@CasinoId = dbo.Aff_GetSportID('Casino')

	DECLARE @month INT
		,@year INT

	SELECT @month = MONTH(@MonthDate)
		,@year = YEAR(@MonthDate)

	--count nrows
	SELECT @NRows = count(1)
	FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK)
		ON ai.AffId = ad.AffId
	WHERE ai.STATUS = 'Approved'
		--and ai.IsClosed=0
		AND ai.Username LIKE @UserName
		AND isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
		--and AffType = @AffType
		AND ai.ApprovedDate < @ToDate

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT
		,@AffectedRows INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	DECLARE @TempAff TABLE (
		AffId INT PRIMARY KEY
		,UserName NVARCHAR(30)
		,IsClosed BIT
		,Commission DECIMAL(9, 8)
		,AffComm MONEY
		)

	INSERT INTO @TempAff
	SELECT m.AffId
		,m.username
		,m.IsClosed
		,0
		,0
	FROM (
		SELECT ROW_NUMBER() OVER (
				ORDER BY ai.IsClosed
					,ai.AffId
				) AS TheCount
			,ai.AffID
			,ai.UserName
			,ad.PreferredLanguage
			,ai.IsClosed
		FROM AffInfo ai WITH (NOLOCK)
			INNER JOIN AffDetail ad WITH (NOLOCK)
			ON ai.AffId = ad.AffId
		WHERE ai.STATUS = 'Approved'
			--and ai.IsClosed=0
			AND ai.Username LIKE @UserName
			AND isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
			--and AffType = @AffType	
			AND ai.ApprovedDate < @ToDate
		) m
	WHERE m.TheCount BETWEEN @RowStart AND @RowEnd

	SELECT @AffectedRows = @@ROWCOUNT

	IF (
			NOT EXISTS (
				SELECT TOP (1) 1
				FROM AffCommission(NOLOCK)
				WHERE winlostdate = @MonthDate
				)
			)
	BEGIN
		IF (datediff(m, current_timestamp, @MonthDate) = 0)
		BEGIN
			--calculate for current month and display the data
			UPDATE t
			SET t.Commission = coalesce(a.commission, 0)
				,t.AffComm = coalesce(a.Amount, 0)
			FROM @TempAff AS t
				CROSS APPLY [dbo].[Aff_CommissionForCurrentMonth](t.AffID) AS a
			WHERE a.SportID = @SportId
		END
		ELSE
		BEGIN
			UPDATE t
			SET t.Commission = coalesce(a.commission, 0)
				,t.AffComm = coalesce(a.Amount, 0)
			FROM @TempAff AS t
				CROSS APPLY [dbo].[Aff_CommissionForMonth](t.AffID, @Month, @Year) AS a
			WHERE a.SportID = @SportId
		END

		--Select the result Data in order
		SELECT t.AffId
			,t.Username
			,t.IsClosed
			,Commission
			,t.AffComm
		FROM @TempAff AS t
		ORDER BY t.IsClosed
			,t.AffId
			,t.Username
	END
	ELSE
	BEGIN
		SELECT t.AffId
			,t.Username
			,t.IsClosed
			,isnull(t2.Commission, 0) AS Commission
			,isnull(t2.AffWinlost, 0) AS AffComm
		FROM @TempAff t
			LEFT JOIN (
			SELECT ac.AffId
				,ac.Commission
				,ac.AffWinlost
			FROM AffCommission ac WITH (NOLOCK)
				INNER JOIN @TempAff t1
				ON t1.AffId = ac.AffId
			WHERE winlostdate = @MonthDate
				AND SportId = @SportId
			) t2
			ON t.AffId = t2.AffId
		ORDER BY t.IsClosed
			,t.AffId
			,t.Username
	END
END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateCommReport] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateCommReport] TO [VNTeam]
