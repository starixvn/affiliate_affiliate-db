ALTER PROCEDURE [dbo].[AffAdmin_AffiliateSel]    
	@UserId int=0, 
	@AffName NVARCHAR(100) = NULL,
	@AffTypes varchar(100) = NULL,
	@Currencies varchar(100) = NULL,
	@CommGroups varchar(1000) = NULL,
	@DateOption tinyint = 0,
	@FromDate smalldatetime = NULL,
	@ToDate smalldatetime = NULL,
	@BaseCurrency tinyint = 0,
	@PreferLanguages varchar(1000) = NULL,
	@SortBy tinyint = 0,
	@ExcludeTest bit = 1,
	@FavoriteOnly bit = 0,
	@Status varchar(1000) = NULL,
	@PageSize int=50,      
	@PageIndex int=1, 
	@TotalPages int=0 OUTPUT,      
	@NRows int=0 OUTPUT,
	@TotalAmount MONEY = 0 OUTPUT 
AS
    
/*    
Task : Get All Affiliate for a specific page      
DB:    
Original:[Aff_CustomerSelAffiliate]      
Revisions:          
 - 20100208@Johnny: show one more column PreferredLanguage  
 - 20130826@Joseph: update currencies and statuses filter    
 - 20130828@Joseph: restrict user permission by currency   
 - 20130912@Victor: add search criteria, restructure the code
                
Param's Explanation: 
• @UserID: Admin UserID
• @AffName: Affiliate name to search 
• @AffType: Affiliate type (1,2...)
• @Currencies: list of currencies separated by commas, Ex: '1,2,3'
• @CommGroups: list of Commission Group
• @DateOption: 
	. None (0): No date criteria
	. Registered Date (1): Registered Date must be between @FromDate and @EndDate
	. Approval Date (2): Approval day must be between @FromDate and @EndDate
• @BaseCurrency
	. Origial (0): original currency
	. System Currency (1): convert to System currency
• @SortBy
	. Affiliate: 0
	. BF: 1
	. Total members: 2
• @ExcludeTest: exclude test account or not
• @FavoriteOnly: list Favorite Affiliate only
• @Status: list of Statuses: All, Approved, Pending, Disapproved, closed, locked
• @PageSize: Number of rows should be returned per each page
• @PageIndex: Current page
• @TotalPages OUTPUT: total pages of this search          
• @NRows OUTPUT: total rows
• @TotalAmount: Total amount in System currency

*/      


SET NOCOUNT ON    

SELECT	@FromDate = dbo.Aff_GetStartDate(@FromDate),  
		@ToDate = dbo.Aff_GetEndDate(@ToDate)

-- Init criteria lists

-- Restrict currency list by user
DECLARE @tmpCurrency TABLE (CurrencyID INT, ExRate FLOAT)

SELECT CAST(val AS INT) AS CurrencyID 
INTO #TblCurrency 
FROM [dbo].[strSplit] ( @Currencies, ',' )

--Insert Currency default of NonCommission (=0)
If (@@ROWCOUNT > 0)
BEGIN
	INSERT INTO @tmpCurrency
	VALUES (0, 0)
END

INSERT INTO @tmpCurrency
SELECT AttributeID, 0 AS ExRate
FROM dbo.Aff_f_GetCurrencybyUser (@userID,1) r
	INNER JOIN #TblCurrency s ON s.CurrencyID = r.AttributeID

DROP TABLE #TblCurrency

-- AffType
DECLARE @AffTypeList TABLE (AffTypeID INT)
INSERT INTO @AffTypeList
SELECT CAST(val AS INT) 
FROM [dbo].[strSplit] ( @AffTypes, ',' )

-- CommGroup
DECLARE @CommGroupList TABLE (CommGroupID INT)
INSERT INTO @CommGroupList
SELECT GroupID 
FROM [dbo].[strSplit] ( @CommGroups, ',' )
	INNER JOIN CommGroup CG (NOLOCK) ON CG.GroupID = CAST(val AS INT) AND CG.IsDeleted = 0 
WHERE CG.Currency IN (SELECT CurrencyID FROM @tmpCurrency)

-- Prefer Languages

DECLARE @PreferLangList TABLE ([LanguageID] varchar(8))
INSERT INTO @PreferLangList
SELECT val 
FROM [dbo].[strSplit] ( @PreferLanguages, ',' )

-- Status
DECLARE @StatusList TABLE (StatusID VARCHAR(30))
DECLARE @Hasclosed INT
DECLARE @Haslocked INT

SELECT @Hasclosed = -1, @Haslocked = -1

INSERT INTO @StatusList
SELECT val 
FROM [dbo].[strSplit] ( @Status, ',' )

IF (@Status IS NULL)
BEGIN
	SELECT @Hasclosed = 1, @Haslocked = 1
END
IF EXISTS(SELECT TOP 1 1 FROM @StatusList WHERE StatusID LIKE 'closed%')
BEGIN
	SELECT @Hasclosed = 1 

	DELETE FROM @StatusList WHERE StatusID LIKE 'closed%'
END
IF EXISTS(SELECT TOP 1 1 FROM @StatusList WHERE StatusID LIKE 'locked%')
BEGIN
	SELECT @Haslocked = 1

	DELETE FROM @StatusList WHERE StatusID LIKE 'locked%'
END

-- Test Account
DECLARE @IsITAdmin BIT
SELECT @IsITAdmin = CASE GroupID WHEN 2 THEN 1 ELSE 0 END FROM AdminUser WHERE custid = @UserId

-- Retrieve data
SELECT AI.AffID, AI.UserName, AI.FirstName, AI.LastName, 
		
		AD.PreferredLanguage, AI.AffType, 
		AI.RegisteredDate, AI.ApprovedDate, 
		(CASE 
				WHEN AI.IsClosed = 1 THEN 'Closed'
				WHEN AI.IsLocked = 1 THEN 'Locked'
				ELSE AI.Status
			END) as Status, AI.TestLevel, AI.GroupID, 
		AI.Currency, AI.BF, CAST(0 AS MONEY) AS ConvertedBF, AI.TotalMembers
INTO #tmpAffList
FROM AffInfo AI (NOLOCK) 
	INNER JOIN AffDetail AD (NOLOCK) ON AD.AffID = AI.AffID
WHERE (@AffName IS NULL OR AI.UserName LIKE '%' + @AffName + '%') AND
	(AI.AffType IN (SELECT AffTypeID FROM @AffTypeList)) AND
	(AI.Currency IN (SELECT CurrencyID FROM @tmpCurrency)) AND
	(AI.Status IN ('Pending', 'Disapproved') or AI.GroupID IN (SELECT CommGroupID FROM @CommGroupList)) AND
	(@DateOption = 0 OR (@DateOption = 1 AND AI.RegisteredDate BETWEEN @FromDate AND @ToDate)
					 OR (@DateOption = 2 AND AI.ApprovedDate BETWEEN @FromDate AND @ToDate)) AND
	(AD.PreferredLanguage IN (SELECT LanguageID FROM @PreferLangList)) AND
	((AI.Status IN (SELECT StatusID FROM @StatusList) AND AI.IsLocked = 0 AND AI.IsClosed = 0)
					 OR AI.IsClosed = @Hasclosed OR AI.IsLocked = @Haslocked
	) AND
	((@ExcludeTest = 1 AND AI.TestLevel=0) OR (@ExcludeTest = 0 AND @IsITAdmin = 1) OR (@ExcludeTest = 0 AND @IsITAdmin = 0 AND AI.TestLevel IN (0,1)))

--Select * from #tmpAffList

-- Filter Favorite Affiliates
IF (@FavoriteOnly = 1)
BEGIN
	DECLARE @FavoriteList TABLE (AffID INT)

	INSERT INTO @FavoriteList
	SELECT AffID FROM AdminFavorite (NOLOCK) WHERE AdminID = @UserId

	DELETE FROM #tmpAffList WHERE AffID NOT IN (SELECT AffID FROM @FavoriteList)
END

-- Calc total amount
DECLARE @SysCurrency INT

SELECT @SysCurrency = C.CurrencyID
FROM SystemSettings S (NOLOCK)
	INNER JOIN Currency C (NOLOCK) ON C.CurrencyCode = S.SValue
WHERE SName LIKE 'SystemCurrency'

UPDATE @tmpCurrency
SET ExRate = (SELECT ISNULL(dbo.Aff_GetExchangeRate(CurrencyID,@SysCurrency,GETDATE()),0))

UPDATE #tmpAffList
SET ConvertedBF = A.BF * C.ExRate
FROM #tmpAffList A
	INNER JOIN @tmpCurrency C ON C.CurrencyID = A.Currency

SELECT @NRows = COUNT(*), @TotalAmount = ISNULL(SUM(ConvertedBF), 0)
FROM #tmpAffList

DECLARE @RowStart int, @RowEnd int       
      
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,      
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1    

SELECT Currency, C.CurrencyCode,
	SUM(CASE WHEN @BaseCurrency = 0 THEN BF ELSE ConvertedBF END) AS Total,
	SUM(L.TotalMembers) AS TotalMembers
FROM #tmpAffList L
	LEFT JOIN Currency C (NOLOCK) ON C.CurrencyID = L.Currency
GROUP BY Currency, C.CurrencyCode


-- Determine the order direction.
DECLARE @Direction INT
SET @Direction = (CASE @SortBy WHEN 0 THEN 1 ELSE -1 END )

;WITH ResTable AS
(	
	SELECT *, 
		ROW_NUMBER() OVER (ORDER BY 
				(CASE @SortBy
					WHEN 0 THEN AffID
					WHEN 1 THEN ConvertedBF--Money after converted
					ELSE TotalMembers
				END), AffID DESC) AS RowNo
	FROM #tmpAffList t
),
SortedResTable AS
(
	SELECT *,ROW_NUMBER() OVER (ORDER BY RowNo*@Direction) AS RowNum
	FROM ResTable	
)

SELECT R.RowNum AS RowNo, R.AffID, R.UserName, 
	R.FirstName, R.LastName, 
	CAST((CASE WHEN f.AffId IS NULL THEN 0 ELSE 1 END) AS BIT) AS Favorite,
	L.LanguageName,
	T.Name AS AffTypeName,R.RegisteredDate, R.ApprovedDate, R.Status, 
	R.TestLevel,
	AT.TypeName AS AccountType,
	cg.GroupID AS CommGroupID, cg.GroupName AS CommGroupName, 
	E.CurrencyCode AS Currency, 
	R.Currency as CurrencyId,
	CASE WHEN @BaseCurrency = 0 THEN R.BF ELSE R.ConvertedBF END AS BF, 
	R.TotalMembers
FROM SortedResTable R
	LEFT JOIN AffType T (NOLOCK) ON T.TypeID = R.AffType
	LEFT JOIN CommGroup cg (NOLOCK) ON R.GroupId = cg.GroupId    
	LEFT JOIN AdminFavorite f (NOLOCK) ON R.AffId = f.AffId and f.AdminId = @UserId    
	LEFT JOIN Currency e (NOLOCK) ON e.CurrencyID = R.Currency
	LEFT JOIN Language L (NOLOCK) ON L.LanguageID = R.PreferredLanguage
	LEFT JOIN AccountType AT ON R.TestLevel = AT.TypeID

WHERE RowNum BETWEEN @RowStart AND @RowEnd
ORDER BY RowNum

DROP TABLE #tmpAffList

GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateSel] TO [vnteam]