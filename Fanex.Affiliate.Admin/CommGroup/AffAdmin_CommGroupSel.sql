/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CommGroupSel] 
	@LicenseeID			INT
	,@GroupName			NVARCHAR(100)	= ''
	,@Currencies		VARCHAR(1000)	= ''
	,@UserCurrencies	VARCHAR(MAX)	= ''
	,@Date				DATETIME
	,@UserId			INT
	,@GroupID			INT				= 0
	,@PageSize			INT				= 50
	,@PageIndex			INT				= 1
	,@GroupIDList		VARCHAR(1000)	= ''	OUTPUT
	,@NRows				INT				= 0		OUTPUT
AS

/*
	Created: 20090719@DungTong
	Task: Search a Commission Group (paging)
	DB: DBAFF.Affiliate_Athena000
	Original:

	Revisions:
		- 20130913@Joseph: new version
		- 20131121@Joseph: filter by TestLevel
		- 20140820@Bobby: Add Deposit & Withdrawal percent - apply SQL stylescope
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]

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
	
	SELECT @IsITAdmin 	= dbo.AffAdmin_f_IsITAdmin(@UserID, @LicenseeID)

	-- Insert statements for procedure here  
	IF @Currencies != 'All'
	BEGIN
		INSERT INTO @TblCurrency
		SELECT c.val
		FROM [dbo].[strSplit](@Currencies, ',') c
			INNER JOIN [dbo].[strSplit](@UserCurrencies, ',') uc ON c.val = uc.val

		-- NoCommission group
		IF @@ROWCOUNT > 0
		BEGIN
			INSERT INTO @TblCurrency
			VALUES (0)
		END
	END

	SELECT @GroupName = '%' + COALESCE(@GroupName, '') + '%'

	---CommGroup Detail va SportName se duoc cache tren web server dung co che notification
	INSERT INTO @CommTmp(GroupID, Currency, MonthDate)
	SELECT GroupID, Currency, MonthDate
	FROM (
		SELECT cg.GroupID, cg.Currency, @CurrentDate AS MonthDate
		FROM dbo.CommGroup cg WITH (NOLOCK)
		WHERE cg.GroupName LIKE @GroupName
			AND IsDeleted = 0
			AND (
				@Currencies = 'All'
				OR (
					@Currencies IS NOT NULL
					AND Currency IN (SELECT val FROM @TblCurrency)
				)
			)
			AND DATEDIFF(m, @CurrentDate, @Date) = 0
		
		UNION 
		SELECT cg.GroupID, cg.Currency, cg.MonthDate
		FROM dbo.CommGroupHistory cg WITH (NOLOCK)
		WHERE GroupName LIKE @GroupName
			AND IsDeleted = 0
			AND (
				@Currencies = 'All'
				OR (
					@Currencies IS NOT NULL
					AND Currency IN (SELECT val FROM @TblCurrency)
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
			,ISNULL(cg.CreatorName, ch.CreatorName) 			AS Creator
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
			LEFT JOIN dbo.CommGroup cg WITH(NOLOCK) ON tmp.GroupId = cg.GroupId AND tmp.MonthDate = @CurrentDate
			LEFT JOIN dbo.CommGroupHistory ch WITH(NOLOCK) ON tmp.GroupId = ch.GroupId AND tmp.MonthDate = ch.MonthDate
			LEFT JOIN dbo.Exchange ex WITH(NOLOCK) ON cg.Currency = ex.ExchangeID
			LEFT JOIN dbo.ExchangeDaily ed WITH(NOLOCK) ON ch.Currency = ed.ExchangeID AND ch.MonthDate = ed.[Date]
		WHERE tmp.RowIDX BETWEEN ((@PageIndex - 1) * @PageSize) + 1 AND @PageSize * (@PageIndex)
	)
	-- final result
	SELECT g.GroupID
		,g.MonthDate
		,g.GroupName
		,g.Description
		,g.Creator
		,g.CreatedDate
		,g.CurrencyID
		,ISNULL(g.Currency, 'All') AS Currency
		,g.QualifiedAmount
		,g.DepositPercent
		,g.WithdrawalPercent
		,ai.NoOfAffiliate
		,@HasCashback AS HasCashback
	FROM CommPaging g
		CROSS APPLY (
			SELECT COUNT(1) AS NoOfAffiliate
			FROM dbo.AffInfo ai WITH (NOLOCK)
			WHERE ai.GroupID = g.GroupID
				AND (@IsITAdmin = 1 OR ai.TestLevel IN (0, 1))
		) AS ai
	ORDER BY g.RowIDX ASC
	
	SELECT @GroupIDList = SUBSTRING(@GroupIDList, 2, LEN(@GroupIDList) - 1)
END
GO