ALTER PROCEDURE [dbo].[AffAdmin_CommGroupSel] 
	@GroupName		NVARCHAR(100)	= ''
	,@Currencies	VARCHAR(1000)	= ''
	,@Date			DATETIME
	,@UserId		INT
	,@GroupID		INT				= 0
	,@PageSize		INT				= 50
	,@PageIndex		INT				= 1
	,@GroupIDList	VARCHAR(1000)	= ''	OUTPUT
	,@NRows			INT				= 0		OUTPUT
AS
/*
Created: 20090719@DungTong
Task : Search a Commission Group (paging)
DB: DB052.Affiliate_MYM
Original:

Revisions:
    - 20130913@Joseph: new version
    - 20131121@Joseph: filter by TestLevel
	- 20140820@Bobby: Add Deposit & Withdrawal percent - apply SQL stylescope

Params Explaination:
*/
BEGIN
	SET NOCOUNT ON

	-- Test Account
	DECLARE @IsITAdmin 		BIT
		,@RowStart 			INT
		,@RowEnd 			INT
		,@AffiliateID 		INT
		,@CurrentDate		SMALLDATETIME
		,@HasCashback		TINYINT
	
	SET @CurrentDate 		= CAST(GETDATE() AS DATE)
	
	DECLARE @TblCurrency 	TABLE (val NVARCHAR(6))
	DECLARE @CommTmp		TABLE (GroupID INT, Currency INT, MonthDate SMALLDATETIME, RowIDX INT IDENTITY(1,1))
	
	SELECT @IsITAdmin 	= CASE ad.GroupID
			WHEN 2 THEN 1
			ELSE 0
			END
	FROM dbo.AdminUser ad WITH(NOLOCK)
	WHERE ad.custid = @UserId

	SELECT AttributeID AS CurrencyID
	INTO #tmpCurrency
	FROM dbo.Aff_f_GetCurrencybyUser(@UserId, 1)

	-- Insert statements for procedure here  
	IF @Currencies != 'All'
	BEGIN
		INSERT INTO @TblCurrency
		SELECT c.val
		FROM [dbo].[strSplit](@Currencies, ',') c
			INNER JOIN #tmpCurrency t ON c.val = t.CurrencyID

		-- NoCommission group
		IF (
				SELECT count(1)
				FROM @TblCurrency
				) > 0
			INSERT INTO @TblCurrency
			VALUES (0)
	END

	SELECT @GroupName = '%' + COALESCE(@GroupName, '') + '%'

	---CommGroup Detail va SportName se duoc cache tren web server dung co che notification
	INSERT INTO @CommTmp(GroupID, Currency, MonthDate)
	SELECT GroupID
		, Currency
		, MonthDate
	FROM (
		SELECT cg.GroupID
			, cg.Currency
			, @CurrentDate AS MonthDate
		FROM dbo.CommGroup cg WITH (NOLOCK)
			WHERE cg.GroupName LIKE @GroupName
				AND IsDeleted = 0
				AND (
					@Currencies = 'All'
					OR (
						@Currencies IS NOT NULL
						AND Currency IN (
							SELECT val
							FROM @TblCurrency
							)
						)
					)
				AND DATEDIFF(m, @CurrentDate, @Date) = 0
		
		UNION 
		SELECT cg.GroupID
			, cg.Currency
			, cg.MonthDate
		FROM dbo.CommGroupHistory cg WITH (NOLOCK)
		WHERE GroupName LIKE @GroupName
			AND IsDeleted = 0
			AND (
				@Currencies = 'All'
				OR (
					@Currencies IS NOT NULL
					AND cg.Currency IN (
						SELECT val
						FROM @TblCurrency
						)
					)
				)
			AND DATEDIFF(m, @Date, cg.MonthDate) = 0
	) tmp
	GROUP BY GroupID, Currency, MonthDate
	ORDER BY GroupID
	
	SELECT @NRows = COUNT(1) 
	FROM @CommTmp
	
	SELECT @GroupIDList = ISNULL(@GroupIDList, '') + ',' + CAST(tmp.GroupID AS VARCHAR(10))
	FROM @CommTmp tmp
	WHERE tmp.RowIDX BETWEEN ((@PageIndex - 1) * @PageSize) + 1 AND @PageSize * (@PageIndex)
	
	--check has cashback
	SELECT @HasCashback = MAX(ct.HasCashback)
	FROM (
		SELECT TOP 1 
			CASE 
				WHEN DATEDIFF(M, ISNULL(d.RemovedDate, GETDATE()), @Date) <= 0 THEN 1 
				ELSE 0 
			END AS HasCashback  
		FROM [dbo].[DeductionType] d WITH(NOLOCK) 
		WHERE [ProductID] = 0  AND [DTypeName] = 'Cashback' 
		
		UNION 
		SELECT HasCashback
		FROM (SELECT 0 AS HasCashback) t
	) ct
			
	;WITH CommPaging AS (
		SELECT tmp.GroupID
			,tmp.MonthDate
			,ISNULL(cg.GroupName, ch.GroupName) 				AS GroupName
			,ISNULL(cg.[Description], ch.[Description]) 		AS [Description]
			,ISNULL(cg.Creator, ch.Creator) 					AS Creator
			,ISNULL(cg.CreatedDate, ch.CreatedDate) 			AS CreatedDate
			,ISNULL(cg.Currency, ch.Currency) 					AS CurrencyID
			,ISNULL(cg.QualifiedAmount, ch.QualifiedAmount)    	AS QualifiedAmount
			,ISNULL(ex.Code, ed.Code) 							AS Currency
			,CASE 
					WHEN DATEDIFF(M, @Date, @CurrentDate) = 0 THEN ISNULL(cg.DepositPercent, ex.DepositPercent) 
					ELSE ISNULL(ch.DepositPercent, ed.DepositPercent) 
				END 											AS DepositPercent
			,CASE 
					WHEN DATEDIFF(M, @Date, @CurrentDate) = 0 THEN ISNULL(cg.WithdrawalPercent, ex.WithdrawalPercent) 
					ELSE ISNULL(ch.WithdrawalPercent, ed.WithdrawalPercent) 
				END 											AS WithdrawalPercent
			,tmp.RowIDX
		FROM @CommTmp tmp
			LEFT JOIN dbo.CommGroup cg WITH(NOLOCK)
			ON tmp.GroupId = cg.GroupId 
				AND tmp.MonthDate = @CurrentDate
			LEFT JOIN dbo.CommGroupHistory ch WITH(NOLOCK)
			ON tmp.GroupId = ch.GroupId 
				AND tmp.MonthDate = ch.MonthDate
			LEFT JOIN dbo.Exchange ex WITH(NOLOCK)
			ON cg.Currency = ex.ExchangeID
			LEFT JOIN dbo.ExchangeDaily ed WITH(NOLOCK)
			ON ch.Currency = ed.ExchangeID 
				AND ch.MonthDate = ed.[Date]
		WHERE tmp.RowIDX BETWEEN ((@PageIndex - 1) * @PageSize) + 1 AND @PageSize * (@PageIndex)
	)
	-- final result
	SELECT g.GroupID
		,g.MonthDate
		,g.GroupName
		,g.Description
		,ISNULL(au.username, 'System') AS Creator
		,g.CreatedDate
		,g.CurrencyID
		,ISNULL(g.Currency, 'All') AS Currency
		,g.QualifiedAmount
		,g.DepositPercent
		,g.WithdrawalPercent
		,ai.NoOfAffiliate
		,@HasCashback AS HasCashback
	FROM CommPaging g
		LEFT JOIN dbo.AdminUser au WITH (NOLOCK) 
		ON au.custid = g.Creator
		CROSS APPLY (
				SELECT COUNT(1) AS NoOfAffiliate
				FROM dbo.AffInfo ai WITH (NOLOCK)
				WHERE ai.GroupID = g.GroupID
					AND (
						@IsITAdmin = 1
						OR ai.TestLevel IN (0, 1)
						)
			) AS ai
	ORDER BY g.RowIDX ASC
	
	SELECT @GroupIDList = SUBSTRING(@GroupIDList, 2, LEN(@GroupIDList) - 1)
	DROP TABLE #tmpCurrency
	
	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupSel] TO [vnteam]
GO

/*
declare @p7 varchar(1000)
declare @p10 int
EXEC AffAdmin_CommGroupSel @GroupName = N''
	,@Currencies = '5,22,34,47,52,56,64,91,98,102,108,109,113,9999'
	,@Date = '2014-09-01 00:00:00'
	,@UserId = 33
	,@GroupID = NULL
	,@GroupIDList = @p7 OUTPUT
	,@NRows = @p10 OUTPUT
select @p7, @p10
go
*/