ALTER FUNCTION [dbo].[AffAdmin_AffiliateListForReport]
(
	@UserId int=0, 
	@AffName NVARCHAR(100) = NULL,
	@AffTypes varchar(100) = NULL,
	@CommGroups varchar(1000) = NULL,
	@PreferLanguages varchar(1000) = NULL,
	@Currencies varchar(100) = NULL,
	@ExcludeTest bit = 1,
	@IsITAdmin bit = 0,
	@FromDate datetime = null,
	@ToDate datetime = null
)
RETURNS @returntable TABLE 
(
	AffId int, 
	Username nvarchar(30),
	AffType varchar(50),
	Language nvarchar(255),
	ExchangeId int,
	Currency varchar(5),
	Status varchar(50),
	MonthDate datetime
)
AS
BEGIN
	Select @AffName = '%' + ISNULL(@AffName, '') + '%'
	-- Restrict currency list by user
	DECLARE @tmpCurrency TABLE (CurrencyID INT)

	-- Currencies
	IF (@Currencies <> 'All')
	BEGIN
		INSERT INTO @tmpCurrency
		SELECT AttributeID
		FROM dbo.Aff_f_GetCurrencybyUser (@userID, 1) r
			INNER JOIN [dbo].[strSplit] (@Currencies, ',' ) s ON s.val = r.AttributeID
	END

	-- Sys exchange rate
	DECLARE @SysCurrency INT

	SELECT @SysCurrency = C.CurrencyID
	FROM SystemSettings S (NOLOCK)
		INNER JOIN Currency C (NOLOCK) ON C.CurrencyCode = S.SValue
	WHERE SName LIKE 'SystemCurrency'

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
	WHERE (@Currencies = 'All' OR CG.Currency IN (SELECT CurrencyID FROM @tmpCurrency))

	-- Prefer Languages
	DECLARE @PreferLangList TABLE ([LanguageID] varchar(8))
	INSERT INTO @PreferLangList
	SELECT val 
	FROM [dbo].[strSplit] ( @PreferLanguages, ',' )


	Declare @CurrentDate datetime
	Select @CurrentDate = [dbo].[Aff_GetFirstDayOfMonth](CURRENT_TIMESTAMP)

	--Get data from current affinfo table
	IF(@CommGroups IS NULL or datediff(m, @CurrentDate, @ToDate) = 0)
	BEGIN
		--Get Affiliate list
		Insert INTO @returntable
		Select ai.AffId, ai.Username, at.Name, l.LanguageName, ex.ExchangeId, Code
			, (CASE 
					WHEN IsClosed = 1 THEN 'Closed'
					WHEN IsLocked = 1 THEN 'Locked'
					ELSE Status
				END) as Status
			, @CurrentDate as MonthDate
		From AffInfo ai with (nolock)
			INNER JOIN AffDetail AD (NOLOCK) ON AD.AffID = AI.AffID
			INNER JOIN Exchange ex with (nolock) on ai.Currency = ex.ExchangeID
			INNER JOIN AffType at WITH (NOLOCK) on ai.AffType = at.TypeID
			INNER JOIN Language l WITH (NOLOCK) on AD.PreferredLanguage = l.LanguageID
		Where 
			ai.Status = 'Approved' AND
			AI.UserName like @AffName AND
			(@AffTypes IS NULL OR AI.AffType IN (SELECT AffTypeID FROM @AffTypeList)) AND
			(@Currencies = 'All' OR AI.Currency IN (SELECT CurrencyID FROM @tmpCurrency)) AND
			(@CommGroups IS NULL OR AI.GroupID IN (SELECT CommGroupID FROM @CommGroupList)) AND
			(@PreferLanguages IS NULL OR AD.PreferredLanguage IN (SELECT LanguageID FROM @PreferLangList)) AND
			((@ExcludeTest = 1 AND AI.TestLevel=0) OR (@ExcludeTest = 0 AND @IsITAdmin = 1) OR (@ExcludeTest = 0 AND @IsITAdmin = 0 AND AI.TestLevel IN (0,1)))
	END
	

	IF (@CommGroups IS NOT NULL)
	BEGIN
		--Get from history comm group table
		IF (datediff(m, @FromDate, @CurrentDate) > 0)
		BEGIN
			Declare @TmpTodate datetime -- last date of the month to get all data
			Select @TmpTodate = [dbo].[Aff_GetLastDayOfMonth](@ToDate)


			Insert INTO @returntable
			Select ai.AffId, ai.Username, at.Name, l.LanguageName, ex.ExchangeId, Code
				, (CASE 
						WHEN IsClosed = 1 THEN 'Closed'
						WHEN IsLocked = 1 THEN 'Locked'
						ELSE Status
					END) as Status
				, tmp.MonthDate
			From AffInfo ai with (nolock)
				INNER JOIN AffDetail AD (NOLOCK) ON AD.AffID = AI.AffID
				INNER JOIN Exchange ex with (nolock) on ai.Currency = ex.ExchangeID
				INNER JOIN AffType at WITH (NOLOCK) on ai.AffType = at.TypeID
				INNER JOIN Language l WITH (NOLOCK) on AD.PreferredLanguage = l.LanguageID
				INNER JOIN 
				(
					SELECT AffId, MonthDate
					FROM AffGroupHistory ag WITH (NOLOCK)
						INNER JOIN @CommGroupList c ON ag.GroupId = c.CommGroupID
					Where MonthDate BETWEEN @FromDate and @TmpTodate						
				) AS tmp on ai.AffID = tmp.AffId
			Where 
				ai.Status = 'Approved' AND
				AI.UserName like @AffName AND
				(@AffTypes IS NULL OR AI.AffType IN (SELECT AffTypeID FROM @AffTypeList)) AND
				(@Currencies = 'All' OR AI.Currency IN (SELECT CurrencyID FROM @tmpCurrency)) AND
				(@PreferLanguages IS NULL OR AD.PreferredLanguage IN (SELECT LanguageID FROM @PreferLangList)) AND
				((@ExcludeTest = 1 AND AI.TestLevel=0) OR (@ExcludeTest = 0 AND @IsITAdmin = 1) OR (@ExcludeTest = 0 AND @IsITAdmin = 0 AND AI.TestLevel IN (0,1)))
		END
	END
	return
END