/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Member_Sel]
	@AffId		INT,
	@MemberType	SMALLINT = 0,
	@FromDate	SMALLDATETIME = NULL,
	@ToDate		SMALLDATETIME = NULL,
	@IsGetAll	BIT = 0,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20250919@Danny
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User Site - Account Overview - Member List

	Revisions:
		- 20250919@Danny: Initialize SP [RedmineID: #128775]
	
	Param's Explanation:
		@MemberType:
			0: All
			1: Non-Deposited
			2: Deposited
*/

BEGIN
	SET NOCOUNT ON

	SELECT @FromDate = CONVERT(DATE, @FromDate), @ToDate = CONVERT(DATE, @ToDate)

	CREATE TABLE #MemberInfo
	(
		CustId			INT
		,UserName		VARCHAR(50)
		,Currency		INT
		,RegisteredDate	DATETIME
	)

	INSERT INTO #MemberInfo (CustId, UserName,  Currency, RegisteredDate)
	SELECT CustId, UserName, Currency, RegisteredDate
	FROM dbo.MemberInfo WITH (NOLOCK)
	WHERE AffId = @AffId
		AND (IsRemoved = 0 OR @IsGetAll = 1)
		AND 1 = CASE @MemberType
					WHEN 0 THEN 1
					WHEN 1 THEN CASE WHEN FirstDepositDate IS NULL THEN 1 ELSE 0 END
					WHEN 2 THEN CASE WHEN FirstDepositDate IS NULL THEN 0 ELSE 1 END
					ELSE 0 END
		AND 1 = CASE @IsGetAll
					WHEN 0 THEN CASE @MemberType
									WHEN 0 THEN CASE WHEN RegisteredDate >= @FromDate AND RegisteredDate < DATEADD(DAY, 1, @ToDate) OR FirstDepositDate >= @FromDate AND FirstDepositDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE 0 END
									WHEN 1 THEN CASE WHEN RegisteredDate >= @FromDate AND RegisteredDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE 0 END
									WHEN 2 THEN CASE WHEN FirstDepositDate >= @FromDate AND FirstDepositDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE 0 END
									ELSE 0 END
					WHEN 1 THEN 1
					ELSE 0 END
	
	SELECT @NRows = @@ROWCOUNT

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1,
			@RowEnd		= @RowStart + @PageSize - 1

	-- Return data
	SELECT CustId, UserName, Currency, RegisteredDate
	FROM
	(
		SELECT mi.CustId, mi.UserName, e.Currency, mi.RegisteredDate,
			ROW_NUMBER() OVER(ORDER BY mi.RegisteredDate DESC) AS RowNum
		FROM #MemberInfo mi
			LEFT JOIN TpExchange t WITH (NOLOCK) ON t.TpExchangeId = mi.Currency
			LEFT JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, mi.Currency) = e.ExchangeID
	) AS result
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #MemberInfo
END
GO