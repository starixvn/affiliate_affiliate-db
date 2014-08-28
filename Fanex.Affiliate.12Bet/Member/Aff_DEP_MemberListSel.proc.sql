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

	SELECT @FromDate = convert(VARCHAR(10), @FromDate, 120)

	SELECT @ToDate = dateadd(s, - 1, dateadd(d, 1, @ToDate))

	-- list removal customer from affiliate_db
	SELECT IBCCustId
		,DepositCustID AS CustID
	INTO #affMemberRemoval
	FROM dbo.MemberInfo m WITH (NOLOCK)
	WHERE m.AffID = @AffiliateID
		AND m.IsRemoved = 1
		AND (CASE 
			WHEN (@FromDate IS NULL	AND @ToDate IS NULL) THEN 1
			WHEN (RegisteredDate BETWEEN @FromDate AND @ToDate) THEN 1
			ELSE 0 END
			) = 1

	-- list custid from deposit_db
	SELECT ROW_NUMBER() OVER (
			ORDER BY creatdate DESC
			) AS TheCount
		,custid
	INTO #depCustomer
	FROM [DBDeposit].deposit_db.dbo.Deposit_Customer c WITH (NOLOCK)
	WHERE AffiliateID = @AffiliateID
		AND (CASE 
			WHEN @MemberType = 0 THEN 1
			WHEN (@MemberType = 1 AND IBCCustID IS NULL) THEN 1
			WHEN (@MemberType = 2 AND IBCCustID IS NOT NULL) THEN 1
			ELSE 0 END
			) = 1
		AND (CASE 
			WHEN (@FromDate IS NULL	AND @ToDate IS NULL) THEN 1
			WHEN (creatdate BETWEEN @FromDate AND @ToDate) THEN 1
			ELSE 0 END
			) = 1
		AND custid NOT IN (
			SELECT custid
			FROM #affMemberRemoval
			)

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
		,firstname
		,lastname
		,username
		,email
		,currency
		,creatdate AS registereddate
		,phone
	FROM #depCustomer p
		INNER JOIN [DBDeposit].deposit_db.dbo.Deposit_Customer c WITH (NOLOCK) 
		ON p.custid = c.custid
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
GRANT VIEW DEFINITION ON [dbo].[Aff_DEP_MemberListSel] TO [VNTeam]
GO
