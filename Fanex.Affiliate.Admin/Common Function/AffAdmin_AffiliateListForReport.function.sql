ALTER FUNCTION [dbo].[AffAdmin_AffiliateListForReport] (
	@UserId 			INT 			= 0
	,@AffName 			NVARCHAR(100) 	= NULL
	,@AffTypes 			VARCHAR(100) 	= NULL
	,@CommGroups 		VARCHAR(1000) 	= NULL
	,@PreferLanguages 	VARCHAR(1000)	= NULL
	,@Currencies 		VARCHAR(100) 	= NULL
	,@ExcludeTest 		BIT 			= 1
	,@IsITAdmin 		BIT 			= 0
	,@FromDate 			DATETIME 		= NULL
	,@ToDate 			DATETIME 		= NULL
	)
RETURNS @returntable TABLE (
	AffId 			INT
	,Username 		NVARCHAR(30)
	,AffType 		VARCHAR(50)
	,LANGUAGE 		NVARCHAR(255)
	,ExchangeId 	INT
	,Currency 		VARCHAR(5)
	,STATUS 		VARCHAR(50)
	,MonthDate 		DATETIME
	,GroupId 		INT
	,GroupName 		NVARCHAR(100)
	)
AS
/*    
	Task : Affiliate report
	DB: [Affiliate_Athena000]
	Original: [AffAdmin_AffiliateListForReport]
	Revisions:
		- 20140204@bobby.nguyen: Get AffGroupHistory info by moving @ToDate to the end date of month
		- 20140216@bobby.nguyen: Hotfix#15018 - filter commgroup for old month data
		- 20140218@bobby.nguyen: Fixbug#15128 - Check NoCommission Group
		- 20140513@Bobby: Add GroupId & GroupName
		- 20140713@Bobby: Checking filer commgroup: include CommGroupHistory

	Param's Explanation: 
*/
BEGIN
	
	DECLARE @SysCurrency 	INT
		,@CurrentDate 		DATETIME
		
	DECLARE @tmpCurrency 	TABLE (CurrencyID 	INT)
		,@AffTypeList 		TABLE (AffTypeID 	INT)
		,@CommGroupList 	TABLE (CommGroupID 	INT)
		,@PreferLangList 	TABLE (LanguageID VARCHAR(8))
	
	--AffName
	SET @AffName = '%' + ISNULL(@AffName, '') + '%'
	
	-- Currencies
	IF (@Currencies <> 'All')
	BEGIN
		INSERT INTO @tmpCurrency
		SELECT AttributeID
		FROM dbo.Aff_f_GetCurrencybyUser(@userID, 1) r
			INNER JOIN [dbo].[strSplit](@Currencies, ',') s ON s.val = r.AttributeID
	END

	--SysCurrency
	SELECT @SysCurrency = C.CurrencyID
	FROM SystemSettings S WITH(NOLOCK)
		INNER JOIN Currency C WITH(NOLOCK) 
		ON C.CurrencyCode = S.SValue
	WHERE SName LIKE 'SystemCurrency'

	-- AffType
	INSERT INTO @AffTypeList
	SELECT CAST(val AS INT)
	FROM [dbo].[strSplit](@AffTypes, ',')

	-- filter CommGroup merge with CommGroupHistory
	INSERT INTO @CommGroupList(GroupID)
	SELECT GroupID
	FROM [dbo].[strSplit](@CommGroups, ',') AS tmp
		INNER JOIN (
			SELECT cg.GroupId
				,cg.GroupName
				,cg.Currency
			FROM dbo.CommGroup cg WITH (NOLOCK)
				LEFT JOIN dbo.CommGroupHistory ch WITH (NOLOCK) 
				ON cg.GroupID = ch.GroupID
			WHERE cg.IsDeleted = 0
				OR (
					cg.IsDeleted = 1
					AND ch.IsDeleted = 0
					)
			GROUP BY cg.GroupId
				,cg.GroupName
				,cg.Currency
		) AS CG 
		ON CG.GroupID = CAST(tmp.val AS INT)
	WHERE @Currencies = 'All'
			OR CG.GroupName IN ('NoCommission')
			OR CG.Currency IN (
				SELECT CurrencyID
				FROM @tmpCurrency
			)

	-- Prefer Languages
	INSERT INTO @PreferLangList
	SELECT val
	FROM [dbo].[strSplit](@PreferLanguages, ',')

	-- CurrentDate
	SET @CurrentDate = [dbo].[Aff_GetFirstDayOfMonth](CURRENT_TIMESTAMP)

	-- reset to current date
	SET @ToDate = CASE WHEN @ToDate > GETDATE() THEN GETDATE() ELSE @ToDate END;

	--Get data from current affinfo table
	IF (@CommGroups IS NULL
		OR DATEDIFF(m, @CurrentDate, @ToDate) = 0
	)
	BEGIN
		--Get Affiliate list
		INSERT INTO @returntable
		SELECT ai.AffId
			,ai.Username
			,at.NAME
			,l.LanguageName
			,ex.ExchangeId
			,Code
			,(CASE 
				WHEN IsClosed = 1 THEN 'Closed'
				WHEN IsLocked = 1 THEN 'Locked'
				ELSE STATUS END
				) AS STATUS
			,@CurrentDate AS MonthDate
			,ai.GroupId
			,cg.GroupName
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN (
				SELECT AffId
					,COUNT(UserName) MemTrans
				FROM dbo.MemberDaily m WITH (NOLOCK)
				WHERE m.WinlostDate >= @FromDate
					AND m.WinlostDate <= @ToDate
				GROUP BY AffId
				HAVING COUNT(UserName) > 0
			) AS mem ON ai.AffId = mem.AffId
			INNER JOIN dbo.AffDetail AD(NOLOCK) 
				ON AD.AffID = AI.AffID
			INNER JOIN dbo.Exchange ex WITH (NOLOCK) 
				ON ai.Currency = ex.ExchangeID
			INNER JOIN dbo.AffType at WITH (NOLOCK) 
				ON ai.AffType = at.TypeID
			INNER JOIN dbo.[LANGUAGE] l WITH (NOLOCK) 
				ON AD.PreferredLanguage = l.LanguageID
			INNER JOIN dbo.CommGroup cg WITH (NOLOCK) 
				ON ai.GroupID = cg.GroupID
		WHERE ai.STATUS = 'Approved'
			AND AI.UserName LIKE @AffName
			AND (
				@AffTypes IS NULL
				OR AI.AffType IN (
					SELECT AffTypeID
					FROM @AffTypeList
					)
				)
			AND (
				@Currencies = 'All'
				OR AI.Currency IN (
					SELECT CurrencyID
					FROM @tmpCurrency
					)
				)
			AND (
				@CommGroups IS NULL
				OR AI.GroupID IN (
					SELECT CommGroupID
					FROM @CommGroupList
					)
				)
			AND (
				@PreferLanguages IS NULL
				OR AD.PreferredLanguage IN (
					SELECT LanguageID
					FROM @PreferLangList
					)
				)
			AND (
				(
					@ExcludeTest = 1
					AND AI.TestLevel = 0
					)
				OR (
					@ExcludeTest = 0
					AND @IsITAdmin = 1
					)
				OR (
					@ExcludeTest = 0
					AND @IsITAdmin = 0
					AND AI.TestLevel IN (0, 1)
					)
				)
	END

	IF (@CommGroups IS NOT NULL
		AND DATEDIFF(m, @FromDate, @CurrentDate) > 0
	)
	BEGIN
		SET @ToDate = dbo.Aff_GetLastDayOfMonth(@ToDate)

		INSERT INTO @returntable
		SELECT ai.AffId
			,ai.Username
			,at.NAME
			,l.LanguageName
			,ex.ExchangeId
			,Code
			,(CASE 
				WHEN IsClosed = 1 THEN 'Closed'
				WHEN IsLocked = 1 THEN 'Locked'
				ELSE STATUS END
				) AS STATUS
			,tmp.MonthDate
			,tmp.GroupId
			,tmp.GroupName
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN (
				SELECT AffId
					,COUNT(UserName) MemTrans
				FROM dbo.MemberDaily m WITH (NOLOCK)
				WHERE m.WinlostDate >= @FromDate
					AND m.WinlostDate <= @ToDate
				GROUP BY AffId
				HAVING COUNT(UserName) > 0
			) AS mem 
				ON ai.AffId = mem.AffId
			INNER JOIN dbo.AffDetail AD(NOLOCK) 
				ON AD.AffID = AI.AffID
			INNER JOIN dbo.Exchange ex WITH (NOLOCK) 
				ON ai.Currency = ex.ExchangeID
			INNER JOIN dbo.AffType at WITH (NOLOCK) 
				ON ai.AffType = at.TypeID
			INNER JOIN dbo.[LANGUAGE] l WITH (NOLOCK) 
				ON AD.PreferredLanguage = l.LanguageID
			INNER JOIN (
				SELECT AffId
					,ag.GroupId
					,cg.GroupName
					,ag.MonthDate
				FROM dbo.AffGroupHistory ag WITH (NOLOCK)
					INNER JOIN @CommGroupList c 
						ON ag.GroupId = c.CommGroupID
					INNER JOIN dbo.CommGroupHistory cg WITH (NOLOCK) 
						ON ag.GroupID = cg.GroupID
						AND ag.MonthDate = cg.MonthDate
				WHERE ag.MonthDate BETWEEN @FromDate
					AND @toDate
			) AS tmp 
				ON ai.AffID = tmp.AffId
		WHERE ai.STATUS = 'Approved'
			AND AI.UserName LIKE @AffName
			AND (
				@AffTypes IS NULL
				OR AI.AffType IN (
					SELECT AffTypeID
					FROM @AffTypeList
					)
				)
			AND (
				@Currencies = 'All'
				OR AI.Currency IN (
					SELECT CurrencyID
					FROM @tmpCurrency
					)
				)
			AND (
				@PreferLanguages IS NULL
				OR AD.PreferredLanguage IN (
					SELECT LanguageID
					FROM @PreferLangList
					)
				)
			AND (
				(
					@ExcludeTest = 1
					AND AI.TestLevel = 0
					)
				OR (
					@ExcludeTest = 0
					AND @IsITAdmin = 1
					)
				OR (
					@ExcludeTest = 0
					AND @IsITAdmin = 0
					AND AI.TestLevel IN (0, 1)
					)
				)
	END

	RETURN
END
