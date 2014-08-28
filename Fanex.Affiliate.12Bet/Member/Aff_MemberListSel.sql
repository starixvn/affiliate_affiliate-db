ALTER PROCEDURE [dbo].[Aff_MemberListSel] 
	@AffUsername	NVARCHAR(50) = NULL
	,@Username		NVARCHAR(30) = NULL
	,@IBCUserName	NVARCHAR(50) = NULL
	,@PageSize		INT = 50
	,@PageIndex		INT = 1
	,@NRows			INT = 0 OUTPUT
AS
/*
	Created: 20090701@VinhTrinh	
	DB: DBAFF12BET/Affiliate_12Bet

	Revisions:		
		-20100112@Peter : 	Shorting the page by CreatedDate . Request from Fan	
		-20140217@Dan: optimize perf
		-20140424@Bobby: formating code
		-20140522@Bobby: Update OUTPUT params and revise logic code
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
		FROM dbo.MemberInfo m WITH (NOLOCK)
		WHERE m.Username LIKE @Username
			AND IBCUserName LIKE @IBCUserName
			AND m.IsRemoved = 0
	END
	ELSE
	BEGIN
		SELECT @NRows = count(1)
		FROM dbo.MemberInfo m WITH (NOLOCK)
		WHERE @AffID = m.AffID
			AND m.Username LIKE @Username
			AND IBCUserName LIKE @IBCUserName
			AND m.IsRemoved = 0
	END

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1
		,@RowEnd = @RowStart + @PageSize - 1

	DECLARE @TempMember TABLE (IBCCustId INT)

	IF (@AffID IS NULL)
	BEGIN
		INSERT INTO @TempMember
		SELECT m.IBCCustId
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY m.CreatedDate DESC
					) AS TheCount
				,m.IBCCustID
			FROM dbo.MemberInfo m WITH (NOLOCK)
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
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY m.CreatedDate DESC
					) AS TheCount
				,m.IBCCustID
			FROM dbo.MemberInfo m WITH (NOLOCK)
			WHERE @AffID = m.AffID
				AND m.Username LIKE @Username
				AND m.IBCUserName LIKE @IBCUserName
				AND m.IsRemoved = 0
			) m
		WHERE m.TheCount BETWEEN @RowStart AND @RowEnd
	END

	-- fetch final results
	SELECT mi.IBCCustID
		,mi.UserName
		,mi.IBCUserName
		,mi.FirstName
		,mi.LastName
		,mi.CreatedDate
		,ISNULL(af.UserName, 'N/A') AS AffUserName
		,ISNULL(sum(CASE 
					WHEN ruben = 1 THEN (winlost - abs(actual_stake) + playercomm) * isnull(e.actualrate2, 1)
					ELSE 0
					END), 0) AS CurrBalance
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		INNER JOIN @TempMember m
		ON mi.IBCCustId = m.IBCCustID
		LEFT JOIN dbo.AffInfo af WITH (NOLOCK)
		ON mi.AffID = af.AffId
		LEFT JOIN bodb02.dbo.bettrans b WITH (NOLOCK)
		ON b.CustID = m.IbcCustID
		LEFT JOIN dbo.Exchange e WITH (NOLOCK)
		ON e.exchangeid = mi.currency
			AND e.UpdatedTime = (
				SELECT max(e1.UpdatedTime)
				FROM dbo.Exchange e1 WITH (NOLOCK)
				WHERE e1.ExchangeID = e.ExchangeID
					AND UpdatedTime <= b.winlostdate
				)
	GROUP BY mi.IBCCustID
		,mi.UserName
		,mi.IBCUserName
		,mi.FirstName
		,mi.LastName
		,mi.CreatedDate
		,af.UserName
	ORDER BY CreatedDate DESC
END
GO

GRANT EXECUTE ON [dbo].[Aff_MemberListSel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_MemberListSel] TO [vnteam]
GO