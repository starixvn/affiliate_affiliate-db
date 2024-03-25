/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_aff,wsv_affv" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_MemberList_Sel] 
	@AffId		INT,
	@FromDate	SMALLDATETIME = NULL,
	@ToDate		SMALLDATETIME = NULL,
	@IsGetAll	BIT = 0,
	@MemberType	TINYINT = 0,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@NRows		INT = 0 OUTPUT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task:
		Admin site - Home - Member
		User site - Your Customers - Member List
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20240321@Eddie: Change Link Server and metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #202712]

	Param's Explanation:
		@MemberType:
			0: all
			1: deposit
			2: non-deposit
*/

BEGIN
	SET NOCOUNT ON

	IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
	BEGIN
		SELECT @ToDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, @ToDate)) -- Add time (23:59:59.000)
	END

	CREATE TABLE #Member
	(
		IBCCustId		INT,
		CustId			INT,
		RegisteredDate	DATETIME,
		firstname		NVARCHAR(50),
		lastname		NVARCHAR(50),
		username		NVARCHAR(50),
		email			NVARCHAR(100),
		currency		INT,
		phone			VARCHAR(50),
		CreatedDate		DATETIME
	)
	
	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql = 'SELECT IBCCustId,CustId,creatdate AS RegisteredDate,firstname,lastname,username,email,currency,phone
					FROM OPENQUERY(DBDEPOSIT2, ''SELECT IBCCustId,CustId,creatdate,firstname,lastname,username,email,currency,phone
												FROM Deposit_DB.dbo.v_Aff_DepCust WITH (NOLOCK)
												WHERE AffiliateID = ' + CONVERT(VARCHAR(10), @AffId)
	
	-- Non-deposit
	IF @MemberType = 1
	BEGIN
		SELECT @sql = @sql + ' AND IBCCustId IS NULL'
	END
	-- Deposit
	ELSE IF @MemberType = 2
	BEGIN
		SELECT @sql = @sql + ' AND IBCCustId IS NOT NULL'
	END

	SELECT @sql = @sql + ''')'

	INSERT INTO #Member
	(
		IBCCustId,
		CustId,
		RegisteredDate,
		firstname,
		lastname,
		username,
		email,
		currency,
		phone
	)
	EXEC (@sql)

	CREATE NONCLUSTERED INDEX IX_RegisteredDate ON #Member (RegisteredDate)

	IF @IsGetAll = 0
	BEGIN
		DELETE #Member WHERE RegisteredDate NOT BETWEEN @FromDate AND @ToDate
	END

	CREATE NONCLUSTERED INDEX IX_IBCCustId ON #Member (IBCCustId)

	-- Exclude removed member
	IF @IsGetAll = 1
	BEGIN
		DELETE m
		FROM #Member m
		WHERE EXISTS (SELECT 1 FROM dbo.MemberInfo mi WITH (NOLOCK)
						WHERE m.IBCCustId = mi.IBCCustId AND mi.IsRemoved = 1)
	END
	ELSE
	BEGIN
		DELETE m
		FROM #Member m
		WHERE EXISTS (SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.RemovedDate BETWEEN @FromDate AND @ToDate AND m.IBCCustId = mr.IBCCustId)
	END

	-- Total rows
	SELECT @NRows = COUNT(1) FROM #Member

	-- Return data
	DECLARE @RowStart INT, @RowEnd INT

	SELECT	@PageIndex	= @PageIndex - 1,
			@RowStart	= @PageSize * @PageIndex + 1,
			@RowEnd		= @RowStart + @PageSize - 1

	;WITH CTE_Member AS
	(
		SELECT *, ROW_NUMBER() OVER (ORDER BY RegisteredDate DESC) AS RowNum
		FROM #Member
	)
	DELETE CTE_Member WHERE RowNum NOT BETWEEN @RowStart AND @RowEnd

	UPDATE m
	SET m.CreatedDate = mi.CreatedDate
	FROM #Member m
		INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON m.IBCCustId = mi.IBCCustId
	
	SELECT
		custid,
		firstname,
		lastname,
		username,
		email,
		currency,
		RegisteredDate,
		phone,
		CreatedDate
	FROM #Member
	ORDER BY RegisteredDate DESC

	DROP TABLE #Member
END
GO