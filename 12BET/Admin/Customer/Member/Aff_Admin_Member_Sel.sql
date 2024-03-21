/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_aff,wsv_affv" isFunction="0" isNested="0"></info>*/
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
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Customer - Member

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20191127@Percy: Sort by Registered Date Descending [RedmineID: #118992]
		- 20240321@Eddie: Change Link Server and metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #202712]
	
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

	IF @IsGetAll = 1
	BEGIN
		IF @MemberType IN (0, 1)
		BEGIN
			INSERT INTO #MemberInfo (IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate)
			SELECT IBCCustId, UserName, FirstName, LastName, Email, Currency, creatdate AS RegisteredDate
			FROM DBDEPOSIT2.Deposit_DB.dbo.v_Aff_DepCust WITH (NOLOCK)
			WHERE AffiliateId = @AffId
				AND IBCCustId IS NULL
		END
		
		IF @MemberType IN (0, 2)
		BEGIN
			INSERT INTO #MemberInfo (IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate)
			SELECT IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate
			FROM dbo.MemberInfo WITH (NOLOCK)
			WHERE AffId = @AffId
				AND IsRemoved = 0
		END
	END
	ELSE
	BEGIN
		IF @MemberType IN (0, 1)
		BEGIN
			INSERT INTO #MemberInfo (IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate)
			SELECT IBCCustId, UserName, FirstName, LastName, Email, Currency, creatdate AS RegisteredDate
			FROM DBDEPOSIT2.Deposit_DB.dbo.v_Aff_DepCust WITH (NOLOCK)
			WHERE AffiliateId = @AffId
				AND IBCCustId IS NULL
				AND creatdate >= @FromDate AND creatdate < DATEADD(DAY, 1, @ToDate)
		END
		
		IF @MemberType IN (0, 2)
		BEGIN
			INSERT INTO #MemberInfo (IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate)
			SELECT IBCCustId, UserName, FirstName, LastName, Email, Currency, RegisteredDate
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE AffId = @AffId
				AND CreatedDate >= @FromDate AND CreatedDate < DATEADD(DAY, 1, @ToDate)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mi.IBCCustID = mr.IBCCustID
						AND RemovedDate >= @FromDate AND RemovedDate < DATEADD(DAY, 1, @ToDate) 
				)
		END
	END

	SELECT @NRows = COUNT(1) FROM #MemberInfo

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
			LEFT JOIN dbo.Exchange_Current e WITH (NOLOCK) ON mi.Currency = e.ExchangeID
	) AS result
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	DROP TABLE #MemberInfo
END
GO