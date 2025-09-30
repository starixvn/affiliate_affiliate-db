ALTER PROCEDURE [dbo].[Aff_DEP_MemberListSel] 
	@AffiliateID INT
	,@FromDate SMALLDATETIME = NULL
	,@ToDate SMALLDATETIME = NULL
	,@MemberType SMALLINT = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*
	Created: 20100812@Peter	
	Task : Get list of member for Affiliate
	DB: DBAFF12BET.Affiliate_12Bet
	Original: DBDEPOSIT.DEPOSIT_DB.DEP_AffiliateSelMemberList
	Revisions:
		-20140715@Bobby: revise code and move DEP_AffiliateSelMemberList from deposit_db to [Aff_DEP_MemberListSel] affiliate db 
		
	Param's Explanation:		
		   @MemberType=1 : None-Deposited members only
		   @MemberType=2 : Deposited members only.
		   @MemberType=0 : All members.
		   @FromDate=@ToDate : Get all members for all registerdate

*/
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #depCustomer(CustId INT, TheCount INT)

	SELECT @FromDate = convert(VARCHAR(10), @FromDate, 120)

	SELECT @ToDate = dateadd(s, - 1, dateadd(d, 1, @ToDate))

	-- list removal customer from affiliate_db
	SELECT IBCCustId
		,DepositCustID AS CustID
	INTO #affMemberRemoval
	FROM dbo.MemberInfo m WITH (NOLOCK)
	WHERE m.AffID = @AffiliateID
		AND m.IsRemoved = 1
		AND (
				(@FromDate IS NULL AND @ToDate IS NULL)
			OR 
				m.IBCCustId IN (
					SELECT IBCCustId
					FROM dbo.MemberRemoval WITH (NOLOCK)
					WHERE RemovedDate BETWEEN @FromDate AND @ToDate
				)
			)
			
	
	
	IF (@MemberType = 0)
	BEGIN
		INSERT INTO #depCustomer(thecount, custid)
		SELECT ROW_NUMBER() OVER (
			ORDER BY creatdate DESC
			) AS TheCount
			,custid
		FROM (
			select distinct custid
				, creatdate
			from ( 
			SELECT custid
				, creatdate
			FROM [DBDeposit].deposit_db.dbo.Deposit_Customer c WITH (NOLOCK)
			WHERE AffiliateID = @AffiliateID
				AND custid NOT IN (
					SELECT custid
					FROM #affMemberRemoval
				)
				AND (
					(@FromDate IS NULL AND @ToDate IS NULL)
					OR (creatdate BETWEEN @FromDate AND @ToDate)
				)
				
			UNION 	
			SELECT DepositCustID AS custid
					,RegisteredDate as creatdate
				FROM dbo.MemberInfo m WITH (NOLOCK)
				WHERE AffId = @AffiliateID
					AND IBCCustId NOT IN (
						SELECT IBCCustId
						FROM #affMemberRemoval
					)
					AND (
						(@FromDate IS NULL AND @ToDate IS NULL)
						OR (createddate BETWEEN @FromDate AND @ToDate)
					)
					AND m.IBCCustID > 0
			) as t1
		) t
	END
	
	IF (@MemberType = 1)
	BEGIN
		INSERT INTO #depCustomer(thecount, custid)
		SELECT ROW_NUMBER() OVER (
			ORDER BY creatdate DESC
			) AS TheCount
			,custid
		FROM [DBDeposit].deposit_db.dbo.Deposit_Customer c WITH (NOLOCK)
		WHERE AffiliateID = @AffiliateID
			AND custid NOT IN (
				SELECT custid
				FROM #affMemberRemoval
			)
			AND (
				(@FromDate IS NULL AND @ToDate IS NULL)
				OR (creatdate BETWEEN @FromDate AND @ToDate)
			)
			AND c.IBCCustID IS NULL
	END
	
	IF (@MemberType = 2)
	BEGIN
		INSERT INTO #depCustomer(thecount, custid)
		SELECT ROW_NUMBER() OVER (
			ORDER BY createddate DESC
			) AS TheCount
			,DepositCustID AS custid
		FROM dbo.MemberInfo m WITH (NOLOCK)
		WHERE AffId = @AffiliateID
			AND IBCCustId NOT IN (
				SELECT IBCCustId
				FROM #affMemberRemoval
			)
			AND (
				(@FromDate IS NULL AND @ToDate IS NULL)
				OR (createddate BETWEEN @FromDate AND @ToDate)
			)
			AND m.IBCCustID > 0
	END
	
	--count nrows    
	SELECT @NRows = COUNT(1)
	FROM #depCustomer

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1;

	-- fetch result
	SELECT p.custid
		,c.firstname
		,c.lastname
		,c.username
		,c.email
		,c.currency
		,c.creatdate AS registereddate
		,c.phone
		,m.CreatedDate
	FROM #depCustomer p
		INNER JOIN [DBDeposit].deposit_db.dbo.Deposit_Customer c WITH (NOLOCK) 
		ON p.custid = c.custid
		LEFT JOIN dbo.MemberInfo m WITH(NOLOCK)
		ON p.custid = m.DepositCustID
		
	WHERE TheCount BETWEEN @RowStart AND @RowEnd
	ORDER BY TheCount

	DROP TABLE #depCustomer
	DROP TABLE #affMemberRemoval

	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[Aff_DEP_MemberListSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_DEP_MemberListSel] TO [bodbDownlineNetView]
GO
