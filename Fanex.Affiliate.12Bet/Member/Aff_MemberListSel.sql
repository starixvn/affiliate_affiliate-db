ALTER PROCEDURE [dbo].[Aff_MemberListSel] 
	@AffUsername NVARCHAR(50) = NULL
	,@Username NVARCHAR(30) = NULL
	,@IBCUserName NVARCHAR(50) = NULL
	,@PageSize INT = 50
	,@PageIndex INT = 1 OUTPUT
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*
	Created: 20090701@VinhTrinh	
	DB: DBAFF12BET/Affiliate_12Bet

	Revisions:		
		-20100112@Peter : 	Shorting the page by CreatedDate . Request from Fan	
		-20140217@Dan: optimize perf
		-20140424@Bobby: formating code
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @AffID INT
		,@CurrDate SMALLDATETIME

	IF @AffUsername IS NOT NULL
	BEGIN
		SELECT @AffID = AffId
		FROM AffInfo WITH (NOLOCK)
		WHERE Username = @AffUsername
	END

	SELECT @CurrDate = dateadd(d, 0, (datediff(d, 0, current_timestamp)))

	SELECT @Username = '%' + isnull(@Username, '') + '%'
		,@IBCUserName = '%' + isnull(@IBCUserName, '') + '%'

	IF (@AffID IS NULL)
	BEGIN
		SELECT @NRows = count(1)
		FROM MemberInfo m WITH (NOLOCK)
		--inner join AffInfo a with(nolock) on m.AffID = a.AffID
		WHERE m.Username LIKE @Username
			AND IBCUserName LIKE @IBCUserName
			AND m.IsRemoved = 0
	END
	ELSE
	BEGIN
		SELECT @NRows = count(1)
		FROM MemberInfo m WITH (NOLOCK)
		--inner join AffInfo a with(nolock) on m.AffID = a.AffID
		WHERE @AffID = m.AffID
			AND m.Username LIKE @Username
			AND IBCUserName LIKE @IBCUserName
			AND m.IsRemoved = 0
	END

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = (CASE 
			WHEN @PageIndex > @TotalPages THEN @TotalPages
			ELSE @PageIndex END
			)
		,@RowStart = @PageSize * (@PageIndex - 1) + 1
		,@RowEnd = @RowStart + @PageSize - 1

	DECLARE @TempMember TABLE (
		IBCCustId INT PRIMARY KEY
		,UserName NVARCHAR(30)
		,IBCUserName NVARCHAR(50)
		,Currency INT
		,FirstName NVARCHAR(50)
		,LastName NVARCHAR(50)
		,CreatedDate DATETIME
		,AffId INT
		,AffUserName NVARCHAR(30)
		)

	--CREATE TABLE #TempMember (IBCCustId int PRIMARY KEY, UserName nvarchar(30), IBCUserName nvarchar(50), Currency int, FirstName nvarchar(50), LastName nvarchar(50), CreatedDate datetime, AffId int, AffUserName nvarchar(30)) 
	IF (@AffID IS NULL)
	BEGIN
		INSERT INTO @TempMember
		SELECT m.IBCCustId
			,m.UserName
			,m.IBCUserName
			,m.Currency
			,m.FirstName
			,m.LastName
			,m.CreatedDate
			,m.AffID
			,m.AffUserName AS AffUserName
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY m.CreatedDate DESC
					) AS TheCount
				,m.IBCCustID
				,m.UserName
				,m.IBCUserName
				,m.Currency AS Currency
				,m.FirstName
				,m.LastName
				,m.CreatedDate
				,m.AffID
				,af.UserName AS AffUserName
			FROM MemberInfo m WITH (NOLOCK)
				INNER JOIN AffInfo af WITH (NOLOCK)
				ON m.AffID = af.AffId
			WHERE m.Username LIKE @Username
				AND m.IBCUserName LIKE @IBCUserName
				AND m.IsRemoved = 0
			) m
		WHERE m.TheCount BETWEEN @RowStart AND @RowEnd
	END
	ELSE
	BEGIN
		INSERT INTO @TempMember
		SELECT m.IBCCustId
			,m.UserName
			,m.IBCUserName
			,m.Currency
			,m.FirstName
			,m.LastName
			,m.CreatedDate
			,m.AffID
			,m.AffUserName AS AffUserName
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY m.CreatedDate DESC
					) AS TheCount
				,m.IBCCustID
				,m.UserName
				,m.IBCUserName
				,m.Currency AS Currency
				,m.FirstName
				,m.LastName
				,m.CreatedDate
				,m.AffID
				,af.UserName AS AffUserName
			FROM MemberInfo m WITH (NOLOCK)
				INNER JOIN AffInfo af WITH (NOLOCK)
				ON m.AffID = af.AffId
			WHERE @AffID = af.AffID
				AND m.Username LIKE @Username
				AND m.IBCUserName LIKE @IBCUserName
				AND m.IsRemoved = 0
			) m
		WHERE m.TheCount BETWEEN @RowStart AND @RowEnd
	END

	SELECT UserName
		,m.IBCCustID
		,IBCUserName
		,FirstName
		,LastName
		,CreatedDate
		,CurrBalance
		,AffUserName
	FROM @TempMember m
		LEFT JOIN (
		SELECT m.IBCCustID
			,isnull(sum(CASE 
						WHEN ruben = 1 THEN (winlost - abs(actual_stake) + playercomm) * isnull(e.actualrate2, 1)
						ELSE 0
						END), 0) AS CurrBalance
		FROM @TempMember m
			LEFT JOIN bodb02.dbo.bettrans b WITH (NOLOCK)
			ON b.CustID = m.IbcCustID
			LEFT JOIN exchange e WITH (NOLOCK)
			ON e.exchangeid = m.currency
				AND e.UpdatedTime = (
					SELECT max(e1.UpdatedTime)
					FROM Exchange e1 WITH (NOLOCK)
					WHERE e1.ExchangeID = e.ExchangeID
						AND UpdatedTime <= b.winlostdate
					)
		GROUP BY m.IBCCustID
		) t
		ON m.IBCCustId = t.IBCCustID
	ORDER BY CreatedDate DESC
END
GO

GRANT EXECUTE ON [dbo].[Aff_MemberListSel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_MemberListSel] TO [vnteam]
GO


