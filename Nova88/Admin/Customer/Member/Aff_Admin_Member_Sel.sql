/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Member_Sel]
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
	Created: 20181001@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Admin Site - Customer - Member

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20191127@Percy: Sort by Registered Date Descending [RedmineID: #118992]
	
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
		IBCCustId INT,
		UserName VARCHAR(50),
		FirstName NVARCHAR(50),
		LastName NVARCHAR(50),
		Email NVARCHAR(200),
		Currency INT,
		RegisteredDate DATETIME
	)

	INSERT INTO #MemberInfo (IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate)
	SELECT IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate
	FROM dbo.MemberInfo WITH (NOLOCK)
	WHERE AffId = @AffId
		AND IsRemoved = 0
		AND 1 = CASE @MemberType
					WHEN 0 THEN 1
					WHEN 1 THEN CASE WHEN IBCCustId IS NULL THEN 1 ELSE 0 END
					WHEN 2 THEN CASE WHEN IBCCustId IS NULL THEN 0 ELSE 1 END
					ELSE 0 END
		AND 1 = CASE @IsGetAll
					WHEN 0 THEN CASE @MemberType
									WHEN 0 THEN 1
									WHEN 1 THEN CASE WHEN RegisteredDate >= @FromDate AND RegisteredDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE 0 END
									WHEN 2 THEN CASE WHEN CreatedDate >= @FromDate AND CreatedDate < DATEADD(DAY, 1, @ToDate) THEN 1 ELSE 0 END
									ELSE 0 END
					WHEN 1 THEN 1
					ELSE 0 END
	
	SELECT @NRows = @@ROWCOUNT

	-- Paging
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1,
			@RowEnd		= @RowStart + @PageSize - 1

	-- Return data
	SELECT IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate
	FROM
	(
		SELECT mi.IBCCustId, mi.UserName, mi.FirstName, mi.LastName, mi.Email, e.Currency, mi.RegisteredDate,
			ROW_NUMBER() OVER(ORDER BY mi.RegisteredDate DESC) AS RowNum
		FROM #MemberInfo mi
			LEFT JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON mi.Currency = e.ExchangeID
	) AS result
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #MemberInfo
END
GO