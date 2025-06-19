/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Deal_Upd]
	@UserId				INT
	,@GroupId			INT
	,@GroupName			NVARCHAR(100) = ''
	,@Description		NVARCHAR(100) = ''
	,@SubCommRate		DECIMAL(9,8)
	--Revenue
	,@QMTurnover		MONEY
	,@IsActivePlayerSum BIT
	,@DeductionList		XML = NULL
	,@TierList			XML = NULL
	--CPA
    ,@CountryCodes      VARCHAR(MAX) = ''
    ,@ActiveDays        SMALLINT
    ,@HoldingDays       SMALLINT = 0
    ,@HoldingTickets    SMALLINT = 0
    ,@Quota             SMALLINT = 0
    ,@CPATierList       XML = NULL
    ,@CPAProductList    XML = NULL
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Edit Deal

	Revisions:
		- 20250526@Lewis: Initialize SP [RedmineID: #228530]

	Parameter's Explanation:
		- @DeductionList xml = N'
			<root>
				<row id="10" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125" percent="0.12" amount="0" isdeductedpercent="True"/>
				<row id="10" productids="1" percent="0.01" amount="0" isdeductedpercent="True"/>
				<row id="10" productids="2" percent="0.007" amount="0" isdeductedpercent="True"/>
				<row id="13" productids="" percent="0.03" amount="0" isdeductedpercent="True"/>
				<row id="14" productids="" percent="0.03" amount="0" isdeductedpercent="True"/>
			</root>'
		- @TierList xml = N'
			<root>
				<row id="1" minamount="-100000000000" minqm="5" commission="0.025" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="2" minamount="-500000" minqm="5" commission="0.015" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="3" minamount="1" minqm="5" commission="0.015" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="4" minamount="6" minqm="10" commission="0.126" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="1" minamount="0" minqm="5" commission="0.03" productids="1"/>
				<row id="1" minamount="0" minqm="5" commission="0" productids="2"/>
				<row id="2" minamount="100" minqm="5" commission="0" productids="2"/>
				<row id="3" minamount="120" minqm="5" commission="0" productids="2"/>
			</root>'
		- @CPATierList xml = N'
			<root>
				<row groupproductid=""1"" tierid=""1"" minfdm=""0"" mintotaldeposit=""0"" minto=""0"" cpaamount=""50"" />
				<row groupproductid=""1"" tierid=""2"" minfdm=""101"" mintotaldeposit=""1001"" minto=""10001"" cpaamount=""75"" />
				<row groupproductid=""2"" tierid=""1"" minfdm=""0"" mintotaldeposit=""0"" minto=""0"" cpaamount=""30"" />
				<row groupproductid=""2"" tierid=""2"" minfdm=""51"" mintotaldeposit=""501"" minto=""5001"" cpaamount=""60"" />
			</root>
		- @CPAProductList xml = N'
			<root>
				<row groupproductid=""1"" productids=""101"" />
				<row groupproductid=""2"" productids=""102,103"" />
			</root>
		- Note: 
			+ Infinite value of MaxAmount is 100,000,000,000
			+ MinAmount is -100,000,000,000 
			+ MaxAM is 1,000,000,000
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'
	
	DECLARE @Duration INT
	DECLARE @StartTime DATETIME = GETDATE()

	DECLARE @CurrentDate DATETIME = DATEADD(HOUR, 12, GETDATE())
	DECLARE @ActionDate DATETIME =  CAST(@CurrentDate AS DATE)
	DECLARE @ToDate DATETIME = '9999-12-31'

	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = EOMONTH(@CurrentDate)
	DECLARE @Infinity_NegativeAmount MONEY = -100000000000
		,@Infinity_PositiveAmount MONEY    = 100000000000
		,@Inifinity_QM INT 				   = 1000000000

	-- =========================
	-- Check permission
	-- =========================
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[Deal]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	-- =========================
	-- Validate info of Deal
	-- =========================
	SELECT @GroupName =TRIM(ISNULL(@GroupName, ''))
	
	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId)
	BEGIN
		-- Group is not existed
		SELECT @ErrCode = 100, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)
		RETURN
	END

	IF @GroupName = ''
	BEGIN
		-- Group name is invalid!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1001, @Language)
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = @GroupName AND IsDeleted = 0 AND GroupId <> @GroupId)
	BEGIN
		-- Group name is already existed
		SELECT @ErrCode = 102, @ErrMsg = N'Deal name already exists!'
		RETURN
	END

	--get GroupType, IsInstant
	DECLARE @GroupTypeId TINYINT, @IsInstant BIT
	SELECT @GroupTypeId = GroupTypeId
			,@IsInstant = IsInstant
	FROM CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId
	
	-- Revenue/Hybrid validation block
	IF @GroupTypeId IN (1,4)
	BEGIN
		-- Deductions
		DECLARE @DeductionSetting TABLE (GroupProductId TINYINT, DeductionId TINYINT, ProductId INT, DeductedPercentage DECIMAL(9,8), DeductedAmount MONEY, IsDeductedPercent BIT)
	
		;WITH CTE_DeductionSetting AS
		(
			SELECT
				ROW_NUMBER() OVER(PARTITION BY t.c.value('@id', 'TINYINT') ORDER BY (SELECT NULL)) AS GroupProductId,
				t.c.value('@id', 'TINYINT') AS DeductionId,
				t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIds,
				t.c.value('@percent', 'DECIMAL(9,8)') AS DeductedPercentage,
				t.c.value('@amount', 'MONEY') AS DeductedAmount,
				t.c.value('@isdeductedpercent', 'BIT') AS IsDeductedPercent
			FROM @DeductionList.nodes('/root/row') AS t(c)
		)
		INSERT INTO @DeductionSetting (GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT ds.GroupProductId, ds.DeductionId, ISNULL(CONVERT(INT, f.value), 0), ISNULL(ds.DeductedPercentage, 0), ISNULL(ds.DeductedAmount, 0), ISNULL(ds.IsDeductedPercent, 0)
		FROM CTE_DeductionSetting ds
			OUTER APPLY string_split(dbo.Aff_f_AddRelatedProducts(ds.ProductIds), ',') f
		OPTION (OPTIMIZE FOR (@DeductionList = NULL), MAXRECURSION 0)

		UPDATE @DeductionSetting
		SET DeductedPercentage	= CASE WHEN IsDeductedPercent = 0 THEN 0 ELSE ISNULL(DeductedPercentage, 0) END
			,DeductedAmount		= CASE WHEN IsDeductedPercent = 1 THEN 0 ELSE ISNULL(DeductedAmount, 0) END

		-- Tier Setting
		DECLARE @TierSetting TABLE (TierID TINYINT, productids VARCHAR(MAX), GroupProductId TINYINT, MinAmount MONEY, MaxAmount MONEY, MinQM INT, MaxQM INT, Commission DECIMAL(9,8), IsNegativeAmount BIT)
	
		INSERT INTO @TierSetting (TierID, productids, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsNegativeAmount)
		SELECT
			t.c.value('@id', 'TINYINT'),
			t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIds,
			t.c.value('@minamount', 'MONEY'),
			t.c.value('@maxamount', 'MONEY'),
			t.c.value('@minqm', 'INT'),
			@Inifinity_QM AS MaxQM,
			t.c.value('@commission', 'DECIMAL(9,8)'),
			CASE WHEN t.c.value('@minamount', 'MONEY') < 0 THEN 1 ELSE 0 END AS IsNegativeAmount
		FROM @TierList.nodes('/root/row') AS t(c)
		OPTION (OPTIMIZE FOR (@TierList = NULL))

		-- Update Group of Products
		UPDATE t
		SET t.GroupProductId = l.GroupProductId
		FROM @TierSetting t
		CROSS APPLY (
			SELECT TOP 1 d.GroupProductId
			FROM @DeductionSetting d 
			WHERE ',' + t.ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), d.ProductId) + ',%'
		) AS l

		-- Update MaxAmount for each tier of each products's group
		UPDATE t1
		SET t1.MaxAmount = t2.MinAmount
		FROM @TierSetting t1
			INNER JOIN @TierSetting t2 ON t1.TierID + 1 = t2.TierID AND t1.GroupProductId = t2.GroupProductId
	
		;WITH CTE AS
		(
			SELECT GroupProductId, MAX(TierID) AS TierID FROM @TierSetting GROUP BY GroupProductId
		)
		UPDATE t
			SET t.MaxAmount = @Infinity_PositiveAmount
		FROM @TierSetting t
			INNER JOIN CTE e ON t.TierID = e.TierID AND t.GroupProductId = e.GroupProductId

		-- Check valid tier setting
        IF EXISTS (SELECT 1 FROM @TierSetting GROUP BY GroupProductId HAVING COUNT(1) > 50) 
        BEGIN
            -- Oops, maximum of 50 tiers are allowed!
            SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1003, @Language)
            RETURN
        END
        
        IF EXISTS(
            SELECT TOP 1 1 FROM @TierSetting WHERE TierId = 1 AND MinAmount > 0
        )
		OR EXISTS(
			SELECT TOP 1 1 FROM  @TierSetting WHERE TierId = 1 AND IsNegativeAmount =  1 AND MinAmount <> @Infinity_NegativeAmount
		)
        BEGIN
            -- 'The first Tier of the Min Net Win column must be = 0 or -∞'
            SELECT @ErrCode = 201, @ErrMsg = dbo.Aff_f_GetMessageById(1010, @Language)
            RETURN
        END

        IF EXISTS (
			SELECT TOP 1 1
            FROM (
				SELECT GroupProductId, MAX(TierID) AS TierID
				FROM @TierSetting
				WHERE IsNegativeAmount = 1 
				GROUP BY GroupProductId
			)n 
				INNER JOIN @TierSetting ts1 ON n.GroupProductId = ts1.GroupProductId AND ts1.TierID = n.TierID
				INNER JOIN @TierSetting ts2 ON  ts1.TierID + 1 = ts2.TierID AND ts1.GroupProductId = ts2.GroupProductId
			WHERE ts2.MinAmount = 0 OR ts2.MinAmount >  1
		)                 
        BEGIN
            -- The next Tier after a negative Tier must start from 1 in the Min Net Win column.
            SELECT @ErrCode = 202, @ErrMsg = dbo.Aff_f_GetMessageById(1011, @Language)
            RETURN
        END

        IF EXISTS(
				SELECT TOP 1 1
				FROM @TierSetting ts1
					INNER JOIN @TierSetting ts2 ON ts1.TierID + 1 = ts2.TierID AND ts1.GroupProductId = ts2.GroupProductId
				 WHERE ts1.MaxAmount > ts2.MaxAmount 
				 	OR ts1.MinAmount > ts2.MinAmount 
			)
        BEGIN
            -- The values in the Min Net Win column must increase sequentially.
            SELECT @ErrCode = 203, @ErrMsg = dbo.Aff_f_GetMessageById(1012, @Language)
            RETURN
        END
	END

	-- CPA/Hybrid validation block
	IF @GroupTypeId IN (3,4)
	BEGIN
		 -- Player Target Country must not be empty
        IF TRIM(@CountryCodes) = ''
        BEGIN
            SELECT @ErrCode = 311, @ErrMsg = N'At least one Target Country must be selected.'
            RETURN
        END

        -- Activity Period (ActiveDays) must not be empty or zero
        IF @ActiveDays <= 0
        BEGIN
            SELECT @ErrCode = 312, @ErrMsg = N'Activity Period cannot be empty. Please check!'
            RETURN
        END
		
        -- Minimum Player Holding Period: If either is required, both must be filled
		IF (@HoldingDays > 0 OR @HoldingTickets > 0)
			AND NOT (@HoldingDays > 0 AND @HoldingTickets > 0)
		BEGIN
			SELECT @ErrCode = 313, @ErrMsg = N'Holding tickets and Holding days must both be between 1 and 30,000.'
			RETURN
		END

        -- Quota: If quota is enabled (not null and > 0), must be filled
        IF @Quota < 0
        BEGIN
            SELECT @ErrCode = 314, @ErrMsg = N'Quota cannot be negative. Please check!'
            RETURN
        END

        -- Validate CPATierList
        IF @CPATierList IS NULL OR @CPATierList.exist('/root/row') = 0
        BEGIN
            SELECT @ErrCode = 302, @ErrMsg = N'Missing or invalid CPA Tier. Please contact your system administrator.'
            RETURN
        END

		-- Parse CPATierList
        DECLARE @CPATier TABLE (
            GroupProductId INT, TierId INT, MinFDM MONEY, MaxFDM MONEY, MinTotalDeposit MONEY, MaxTotalDeposit MONEY, MinTO MONEY, MaxTO MONEY, CPAAmount MONEY
        )
        INSERT INTO @CPATier (GroupProductId, TierId, MinFDM, MinTotalDeposit, MinTO, CPAAmount)
        SELECT
            t.c.value('@groupproductid', 'INT'),
            t.c.value('@tierid', 'INT'),
            t.c.value('@minfdm', 'MONEY'),
            t.c.value('@mintotaldeposit', 'MONEY'),
            t.c.value('@minto', 'MONEY'),
            t.c.value('@cpaamount', 'MONEY')
        FROM @CPATierList.nodes('/root/row') AS t(c)
		
        -- CPATierList: Oops, maximum of 50 tiers are allowed!
		IF EXISTS (SELECT 1 FROM @CPATier GROUP BY GroupProductId HAVING COUNT(1) > 50) 
        BEGIN
            SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1003, @Language)
            RETURN
        END

		 -- CPATierList: Please select at least one condition: Min FDM, Min Total Deposit, or Min Turnover.
        IF EXISTS (
            SELECT 1 FROM @CPATier
            WHERE GroupProductId IS NULL OR TierId IS NULL OR CPAAmount IS NULL
                OR (ISNULL(MinFDM,0) = 0 AND ISNULL(MinTotalDeposit,0) = 0 AND ISNULL(MinTO,0) = 0)
        )
        BEGIN
            SELECT @ErrCode = 309, @ErrMsg = N'Please select at least one condition: Min FDM, Min Total Deposit, or Min Turnover.'
            RETURN
        END
		
		-- IF CPATierList exist MinWagering => @IsInstant = 0
		IF EXISTS (SELECT 1 FROM @CPATier WHERE MinTO IS NOT NULL)
			AND @IsInstant = 1
		BEGIN
			SELECT @ErrCode = 309, @ErrMsg = N'Instant Payment is unavailable when Min Turnover is enabled. Please contact your system administrator.'
            RETURN
		END	
		
		-- IF CPATierList exist MinWagering => CPAProductList is required
		IF EXISTS (SELECT 1 FROM @CPATier WHERE MinTO IS NOT NULL)
			AND @CPAProductList IS NULL
		BEGIN
			SELECT @ErrCode = 309, @ErrMsg = N'Missing or invalid CPA product list. Please contact your system administrator.'
            RETURN
		END

        -- CPATierList: CPA Amount must be > 0
        IF EXISTS (
            SELECT 1 FROM @CPATier WHERE CPAAmount < 0
        )
        BEGIN
            SELECT @ErrCode = 309, @ErrMsg = N'CPA Amount cannot be negative.'
            RETURN
        END
		
        -- CPATierList: No duplicate (groupproductid, tierid)
        IF EXISTS (
            SELECT GroupProductId, TierId, COUNT(1) FROM @CPATier GROUP BY GroupProductId, TierId HAVING COUNT(1) > 1
        )
        BEGIN
            SELECT @ErrCode = 309, @ErrMsg = N'Each group and tier combination must be unique. Please contact your administrator to review the configuration.'
            RETURN
        END
		
		-- CPAProductlist validate
		IF @CPAProductList IS NOT NULL
		BEGIN
			-- Parse CPAProductList
			DECLARE @CPAProduct TABLE (GroupProductId INT, ProductId INT)

			;WITH cte_CPAProductlist AS(
				SELECT
					t.c.value('@groupproductid', 'INT') AS GroupProductId,
					t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIDs
				FROM @CPAProductList.nodes('/root/row') AS t(c)
			)
			INSERT INTO @CPAProduct (GroupProductId, ProductId)
			SELECT cte.GroupProductId, CAST(s.value AS INT)
			FROM cte_CPAProductlist cte
				OUTER APPLY string_split(dbo.Aff_f_AddRelatedProducts(cte.ProductIDs),',') s
			OPTION (OPTIMIZE FOR (@CPAProductList = NULL), MAXRECURSION 0)

			-- CPAProductList: Check for required fields
			IF EXISTS (SELECT 1 FROM @CPAProduct WHERE GroupProductId IS NULL OR ProductId IS NULL)
			BEGIN
				SELECT @ErrCode = 303, @ErrMsg = N'CPA product list: Missing required fields (GroupProductId or ProductId).'
				RETURN
			END

			-- CPAProductList: Check for duplicates
			IF EXISTS (
				SELECT ProductId, COUNT(1) FROM @CPAProduct GROUP BY ProductId HAVING COUNT(1) > 1
			)
			BEGIN
				SELECT @ErrCode = 304, @ErrMsg = N'CPA product list: Duplicate Productid found.'
				RETURN
			END

			-- CPATierList: At least one tier per product in CPAProductList
			IF EXISTS (
				SELECT 1 FROM @CPAProduct p
				WHERE NOT EXISTS (
					SELECT 1 FROM @CPATier t WHERE t.GroupProductId = p.GroupProductId
				)
			)
			BEGIN
				SELECT @ErrCode = 309, @ErrMsg = N'CPA tier list: Each product must have at least one tier.'
				RETURN
			END
		END

        -- Calculate Max values for each tier per group product
        UPDATE t1
        SET MaxFDM = t2.MinFDM,
            MaxTotalDeposit = t2.MinTotalDeposit,
            MaxTO = t2.MinTO
        FROM @CPATier t1
        INNER JOIN @CPATier t2 ON t1.GroupProductId = t2.GroupProductId AND t1.TierId + 1 = t2.TierId

        -- Set max for last tier to constant
        DECLARE @CPAMax MONEY = 100000000000
        ;WITH LastTiers AS (
            SELECT GroupProductId, MAX(TierId) AS MaxTierId FROM @CPATier GROUP BY GroupProductId
        )
        UPDATE t
        SET MaxFDM = IIF(MinFDM IS NULL,NULL,@CPAMax), MaxTotalDeposit = IIF(MinTotalDeposit IS NULL,NULL,@CPAMax), MaxTO = IIF(MinTO IS NULL,NULL,@CPAMax)
        FROM @CPATier t
        INNER JOIN LastTiers l ON t.GroupProductId = l.GroupProductId AND t.TierId = l.MaxTierId

        -- Validation: min of next tier > min of previous tier for each group product
        IF EXISTS (
            SELECT 1 FROM (
                SELECT GroupProductId, TierId, MinFDM, MinTotalDeposit, MinTO,
                    LEAD(MinFDM) OVER (PARTITION BY GroupProductId ORDER BY TierId) AS NextMinFDM,
                    LEAD(MinTotalDeposit) OVER (PARTITION BY GroupProductId ORDER BY TierId) AS NextMinTotalDeposit,
                    LEAD(MinTO) OVER (PARTITION BY GroupProductId ORDER BY TierId) AS NextMinTO
                FROM @CPATier
            ) t
            WHERE (NextMinFDM IS NOT NULL AND NextMinFDM <= MinFDM)
               OR (NextMinTotalDeposit IS NOT NULL AND NextMinTotalDeposit <= MinTotalDeposit)
               OR (NextMinTO IS NOT NULL AND NextMinTO <= MinTO)
        )
        BEGIN
            SELECT @ErrCode = 309, @ErrMsg = N'CPA tier list: The min value of each next tier must be greater than the previous tier for the same group product.'
            RETURN
        END
	END
	
	-- =========================
	-- UPDATE DATA
	-- =========================
	CREATE TABLE #updateData
	(
		-- 1: general, 2: tier, 3: deduction
		TypeId					TINYINT
		-- General information
		,SubCommRate			DECIMAL(9,8)
		,GroupName				NVARCHAR(100)
		,QMTurnover				MONEY
		,Description			NVARCHAR(100)
		,ActiveDays				SMALLINT
		,HoldingDays			SMALLINT
		,HoldingTickets			SMALLINT
		,Quota					SMALLINT
		,CountryCodes			VARCHAR(MAX)
		-- Tier List
		,TierId					TINYINT
		,MinAmount				MONEY
		,MaxAmount				MONEY
		,MinQM					INT
		,MaxQM					INT
		,Commission				DECIMAL(9, 8)
		,IsActivePlayerSum		BIT
		-- Deduction List
		,GroupProductId			TINYINT
		,DeductionId			TINYINT
		,ProductId				INT
		,DeductedPercentage		DECIMAL(9, 8)
		,DeductedAmount			MONEY
		,IsDeductedPercent		BIT
	)
	DECLARE @old_CPAGroupSetting TABLE(
		-- 1: OLD, 2: NEW
		TypeId TINYINT
		,FromDate DATETIME
		,ToDate DATETIME
		,GroupId INT
		,GroupTypeId INT
		,SubCommRate DECIMAL(9,8)
		,ActiveDays SMALLINT
		,HoldingDays SMALLINT
		,HoldingTickets SMALLINT
		,Quota SMALLINT
		,CountryCodes VARCHAR(MAX)
		,IsInstant BIT
	)
	DECLARE @old_CPATierSetting TABLE(
		-- 1: OLD, 2: NEW
		TypeId INT
		,FromDate DATETIME
		,ToDate DATETIME
		,GroupId INT
		,GroupProductId TINYINT
		,TierId INT
		,MinFDM MONEY
		,MaxFDM MONEY
		,MinTotalDeposit MONEY
		,MaxTotalDeposit MONEY
		,MinTO MONEY
		,MaxTO MONEY
		,CPAAmount MONEY
	)
	DECLARE @old_CPAProductSetting TABLE(
		-- 1: OLD, 2: NEW
		TypeId INT
		,FromDate DATETIME
		,ToDate DATETIME
		,GroupId INT
		,GroupProductId INT
		,ProductId INT
	)

	-- TODO: UPDATE SETTING
	-- General information
	UPDATE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
	SET GroupName = @GroupName
		, Description = @Description
		, SubCommRate = @SubCommRate
		, QMTurnover = @QMTurnover
		, ActiveDays = @ActiveDays
		, HoldingDays = @HoldingDays
		, HoldingTickets = @HoldingTickets
		, Quota = @Quota
		, CountryCodes = @CountryCodes
		, UpdatedBy = @UserId
		, UpdatedTime = @CurrentDate
	OUTPUT DELETED.GroupName, DELETED.SubCommRate, DELETED.Description, DELETED.QMTurnover
		, DELETED.ActiveDays, DELETED.HoldingDays, DELETED.HoldingTickets, DELETED.Quota, DELETED.CountryCodes
		,1
	INTO #updateData (GroupName, SubCommRate, Description, QMTurnover
		, ActiveDays, HoldingDays, HoldingTickets, Quota, CountryCodes
		, TypeId)
	WHERE GroupId = @GroupId

	IF @GroupTypeId = 1 -- Revenue Share by Winloss
	BEGIN
		-- CommGroupHistory
		DELETE dbo.CommGroupHistory WITH(ROWLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.CommGroupHistory (GroupId, MonthDate, SubCommRate, QMTurnover)
		SELECT @GroupId, @MonthDate, @SubCommRate, @QMTurnover

		-- Tier List
		DELETE dbo.TierSetting WITH (ROWLOCK)
			OUTPUT DELETED.TierId, DELETED.GroupProductId, DELETED.MinAmount, DELETED.MaxAmount, DELETED.MinQM, DELETED.MaxQM, DELETED.Commission, DELETED.IsActivePlayerSum, 2
		INTO #updateData (TierId, GroupProductId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum, TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, @IsActivePlayerSum FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory (GroupId, GroupProductId, MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, @MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, @IsActivePlayerSum FROM @TierSetting

		-- Deduction List
		DELETE dbo.DeductionSetting WITH (ROWLOCK)
			OUTPUT DELETED.DeductionId, DELETED.ProductId, DELETED.GroupProductId, DELETED.DeductedPercentage, DELETED.DeductedAmount, DELETED.IsDeductedPercent, 3
		INTO #updateData (DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent, TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.DeductionSetting (GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, @MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting
	END

	IF @GroupTypeId = 3 -- CPA
	BEGIN
		-- CPAGroupSetting
		IF EXISTS (
			SELECT 1 FROM CPAGroupSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate
			  AND (
					ISNULL(SubCommRate, 0) <> ISNULL(@SubCommRate, 0)
				 OR ISNULL(ActiveDays, 0) <> ISNULL(@ActiveDays, 0)
				 OR ISNULL(HoldingDays, 0) <> ISNULL(@HoldingDays, 0)
				 OR ISNULL(HoldingTickets, 0) <> ISNULL(@HoldingTickets, 0)
				 OR ISNULL(Quota, 0) <> ISNULL(@Quota, 0)
				 OR ISNULL(CountryCodes, '') <> ISNULL(@CountryCodes, '')
				 OR ISNULL(IsInstant, 0) <> ISNULL(@IsInstant, 0)
				 )
		)
		BEGIN
			-- Old data
			INSERT INTO @old_CPAGroupSetting(TypeId,FromDate,ToDate,GroupId,GroupTypeId,SubCommRate,ActiveDays,HoldingDays,HoldingTickets,Quota,CountryCodes,IsInstant)
			SELECT 1,FromDate,ToDate,GroupId,GroupTypeId,SubCommRate,ActiveDays,HoldingDays,HoldingTickets,Quota,CountryCodes,IsInstant
			FROM CPAGroupSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Update current row in CPAGroupSetting --> Todate = ActionDate
			UPDATE CPAGroupSetting WITH (ROWLOCK, UPDLOCK)
			SET ToDate = DATEADD(dd,-1,@ActionDate)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Insert new row into CPAGroupSetting --> FromDate = ActionDate + 1
			INSERT INTO CPAGroupSetting (FromDate, ToDate, GroupId, GroupTypeId, SubCommRate, ActiveDays, HoldingDays, HoldingTickets, Quota, CountryCodes, IsInstant)
			VALUES (@ActionDate, @ToDate, @GroupId, @GroupTypeId, @SubCommRate, @ActiveDays, @HoldingDays, @HoldingTickets, @Quota, @CountryCodes, @IsInstant)
			;
		END

		-- CPATierSetting: Add/Remove/Change
		IF EXISTS (
				SELECT 1
				FROM CPATierSetting t WITH (NOLOCK)
				FULL OUTER JOIN @CPATier n
					ON t.GroupId = @GroupId AND t.ToDate = @ToDate
					AND t.GroupProductId = n.GroupProductId AND t.TierId = n.TierId
				WHERE 
					t.GroupProductId IS NULL OR n.GroupProductId IS NULL -- add/remove
					OR ISNULL(t.MinFDM,0) <> ISNULL(n.MinFDM,0)
					OR ISNULL(t.MaxFDM,0) <> ISNULL(n.MaxFDM,0)
					OR ISNULL(t.MinTotalDeposit,0) <> ISNULL(n.MinTotalDeposit,0)
					OR ISNULL(t.MaxTotalDeposit,0) <> ISNULL(n.MaxTotalDeposit,0)
					OR ISNULL(t.MinTO,0) <> ISNULL(n.MinTO,0)
					OR ISNULL(t.MaxTO,0) <> ISNULL(n.MaxTO,0)
					OR ISNULL(t.CPAAmount,0) <> ISNULL(n.CPAAmount,0)
		)
		BEGIN
			-- Old data
			INSERT INTO @old_CPATierSetting(TypeId,FromDate,ToDate,GroupId,GroupProductId,TierId,MinFDM,MaxFDM,MinTotalDeposit,MaxTotalDeposit,MinTO,MaxTO,CPAAmount)
			SELECT 1,FromDate,ToDate,GroupId,GroupProductId,TierId,MinFDM,MaxFDM,MinTotalDeposit,MaxTotalDeposit,MinTO,MaxTO,CPAAmount
			FROM CPATierSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Remove/Change: Update ToDate for removed/changed
			UPDATE t
			SET ToDate = DATEADD(dd,-1,@ActionDate)
			FROM CPATierSetting t WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN @CPATier n
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.TierId = n.TierId
			WHERE t.GroupId = @GroupId AND t.ToDate = @ToDate
			  AND (
					n.GroupProductId IS NULL -- removed
					OR ISNULL(t.MinFDM,0) <> ISNULL(n.MinFDM,0)
					OR ISNULL(t.MaxFDM,0) <> ISNULL(n.MaxFDM,0)
					OR ISNULL(t.MinTotalDeposit,0) <> ISNULL(n.MinTotalDeposit,0)
					OR ISNULL(t.MaxTotalDeposit,0) <> ISNULL(n.MaxTotalDeposit,0)
					OR ISNULL(t.MinTO,0) <> ISNULL(n.MinTO,0)
					OR ISNULL(t.MaxTO,0) <> ISNULL(n.MaxTO,0)
					OR ISNULL(t.CPAAmount,0) <> ISNULL(n.CPAAmount,0)
			  );

			-- Add/Change: Insert new rows for added/changed
			INSERT INTO CPATierSetting (FromDate, ToDate, GroupId, GroupProductId, TierId, MinFDM, MaxFDM, MinTotalDeposit, MaxTotalDeposit, MinTO, MaxTO, CPAAmount)
			SELECT @ActionDate, @ToDate, @GroupId, n.GroupProductId, n.TierId, n.MinFDM, n.MaxFDM, n.MinTotalDeposit, n.MaxTotalDeposit, n.MinTO, n.MaxTO, n.CPAAmount
			FROM @CPATier n
			LEFT JOIN CPATierSetting t WITH (NOLOCK)
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.TierId = n.TierId
			WHERE t.GroupProductId IS NULL -- added
				OR ISNULL(t.MinFDM,0) <> ISNULL(n.MinFDM,0)
				OR ISNULL(t.MaxFDM,0) <> ISNULL(n.MaxFDM,0)
				OR ISNULL(t.MinTotalDeposit,0) <> ISNULL(n.MinTotalDeposit,0)
				OR ISNULL(t.MaxTotalDeposit,0) <> ISNULL(n.MaxTotalDeposit,0)
				OR ISNULL(t.MinTO,0) <> ISNULL(n.MinTO,0)
				OR ISNULL(t.MaxTO,0) <> ISNULL(n.MaxTO,0)
				OR ISNULL(t.CPAAmount,0) <> ISNULL(n.CPAAmount,0)
			;
		END

		-- CPAProductSetting: Add/Remove
		IF EXISTS (
			SELECT 1
			FROM (
				SELECT t.GroupProductId, t.ProductId
				FROM CPAProductSetting t WITH (NOLOCK)
				WHERE t.GroupId = @GroupId AND t.ToDate = @ToDate
			) cur
			FULL OUTER JOIN (
				SELECT n.GroupProductId, n.ProductId
				FROM @CPAProduct n
			) new
			ON cur.GroupProductId = new.GroupProductId AND cur.ProductId = new.ProductId
			WHERE cur.GroupProductId IS NULL OR new.GroupProductId IS NULL
		)
		BEGIN
			-- Old data
			INSERT INTO @old_CPAProductSetting(TypeId,FromDate,ToDate,GroupId,GroupProductId,ProductId)
			SELECT 1,FromDate,ToDate,GroupId,GroupProductId,ProductId
			FROM CPAProductSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Remove: Update ToDate for removed
			UPDATE t
			SET ToDate = DATEADD(dd,-1,@ActionDate)
			FROM CPAProductSetting t WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN @CPAProduct n
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.ProductId = n.ProductId
			WHERE t.GroupId = @GroupId AND t.ToDate = @ToDate
			  AND n.GroupProductId IS NULL;

			-- Add: Insert new rows for added
			INSERT INTO CPAProductSetting (FromDate, ToDate, GroupId, GroupProductId, ProductId)
			SELECT @ActionDate, @ToDate, @GroupId, n.GroupProductId, n.ProductId
			FROM @CPAProduct n
			LEFT JOIN CPAProductSetting t WITH (NOLOCK)
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.ProductId = n.ProductId
			WHERE t.GroupProductId IS NULL
			;
		END
	END

	IF @GroupTypeId = 4 -- Hydrid
	BEGIN
		-- ==========================
		-- Revenue Sharing by Winloss
		-- ==========================
		-- CommGroupHistory
		DELETE dbo.CommGroupHistory WITH(ROWLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.CommGroupHistory (GroupId, MonthDate, SubCommRate, QMTurnover)
		SELECT @GroupId, @MonthDate, @SubCommRate, @QMTurnover

		-- Tier List
		DELETE dbo.TierSetting WITH (ROWLOCK)
			OUTPUT DELETED.TierId, DELETED.GroupProductId, DELETED.MinAmount, DELETED.MaxAmount, DELETED.MinQM, DELETED.MaxQM, DELETED.Commission, DELETED.IsActivePlayerSum, 2
		INTO #updateData (TierId, GroupProductId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum, TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, @IsActivePlayerSum FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory (GroupId, GroupProductId, MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, @MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, @IsActivePlayerSum FROM @TierSetting

		-- Deduction List
		DELETE dbo.DeductionSetting WITH (ROWLOCK)
			OUTPUT DELETED.DeductionId, DELETED.ProductId, DELETED.GroupProductId, DELETED.DeductedPercentage, DELETED.DeductedAmount, DELETED.IsDeductedPercent, 3
		INTO #updateData (DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent, TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.DeductionSetting (GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, @MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting
		
		-- ==========================
		-- CPA
		-- ==========================
		-- CPAGroupSetting
		IF EXISTS (
			SELECT 1 FROM CPAGroupSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate
			  AND (
					ISNULL(SubCommRate, 0) <> ISNULL(@SubCommRate, 0)
				 OR ISNULL(ActiveDays, 0) <> ISNULL(@ActiveDays, 0)
				 OR ISNULL(HoldingDays, 0) <> ISNULL(@HoldingDays, 0)
				 OR ISNULL(HoldingTickets, 0) <> ISNULL(@HoldingTickets, 0)
				 OR ISNULL(Quota, 0) <> ISNULL(@Quota, 0)
				 OR ISNULL(CountryCodes, '') <> ISNULL(@CountryCodes, '')
				 OR ISNULL(IsInstant, 0) <> ISNULL(@IsInstant, 0)
				 )
		)
		BEGIN
			-- Old data
			INSERT INTO @old_CPAGroupSetting(TypeId,FromDate,ToDate,GroupId,GroupTypeId,SubCommRate,ActiveDays,HoldingDays,HoldingTickets,Quota,CountryCodes,IsInstant)
			SELECT 1,FromDate,ToDate,GroupId,GroupTypeId,SubCommRate,ActiveDays,HoldingDays,HoldingTickets,Quota,CountryCodes,IsInstant
			FROM CPAGroupSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Update current row in CPAGroupSetting --> Todate = ActionDate
			UPDATE CPAGroupSetting WITH (ROWLOCK, UPDLOCK)
			SET ToDate = DATEADD(dd,-1,@ActionDate)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Insert new row into CPAGroupSetting --> FromDate = ActionDate + 1
			INSERT INTO CPAGroupSetting (FromDate, ToDate, GroupId, GroupTypeId, SubCommRate, ActiveDays, HoldingDays, HoldingTickets, Quota, CountryCodes, IsInstant)
			VALUES (@ActionDate, @ToDate, @GroupId, @GroupTypeId, @SubCommRate, @ActiveDays, @HoldingDays, @HoldingTickets, @Quota, @CountryCodes, @IsInstant)
			;
		END

		-- CPATierSetting: Add/Remove/Change
		IF EXISTS (
				SELECT 1
				FROM CPATierSetting t WITH (NOLOCK)
				FULL OUTER JOIN @CPATier n
					ON t.GroupId = @GroupId AND t.ToDate = @ToDate
					AND t.GroupProductId = n.GroupProductId AND t.TierId = n.TierId
				WHERE 
					t.GroupProductId IS NULL OR n.GroupProductId IS NULL -- add/remove
					OR ISNULL(t.MinFDM,0) <> ISNULL(n.MinFDM,0)
					OR ISNULL(t.MaxFDM,0) <> ISNULL(n.MaxFDM,0)
					OR ISNULL(t.MinTotalDeposit,0) <> ISNULL(n.MinTotalDeposit,0)
					OR ISNULL(t.MaxTotalDeposit,0) <> ISNULL(n.MaxTotalDeposit,0)
					OR ISNULL(t.MinTO,0) <> ISNULL(n.MinTO,0)
					OR ISNULL(t.MaxTO,0) <> ISNULL(n.MaxTO,0)
					OR ISNULL(t.CPAAmount,0) <> ISNULL(n.CPAAmount,0)
		)
		BEGIN
			-- Old data
			INSERT INTO @old_CPATierSetting(TypeId,FromDate,ToDate,GroupId,GroupProductId,TierId,MinFDM,MaxFDM,MinTotalDeposit,MaxTotalDeposit,MinTO,MaxTO,CPAAmount)
			SELECT 1,FromDate,ToDate,GroupId,GroupProductId,TierId,MinFDM,MaxFDM,MinTotalDeposit,MaxTotalDeposit,MinTO,MaxTO,CPAAmount
			FROM CPATierSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Remove/Change: Update ToDate for removed/changed
			UPDATE t
			SET ToDate = DATEADD(dd,-1,@ActionDate)
			FROM CPATierSetting t WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN @CPATier n
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.TierId = n.TierId
			WHERE t.GroupId = @GroupId AND t.ToDate = @ToDate
			  AND (
					n.GroupProductId IS NULL -- removed
					OR ISNULL(t.MinFDM,0) <> ISNULL(n.MinFDM,0)
					OR ISNULL(t.MaxFDM,0) <> ISNULL(n.MaxFDM,0)
					OR ISNULL(t.MinTotalDeposit,0) <> ISNULL(n.MinTotalDeposit,0)
					OR ISNULL(t.MaxTotalDeposit,0) <> ISNULL(n.MaxTotalDeposit,0)
					OR ISNULL(t.MinTO,0) <> ISNULL(n.MinTO,0)
					OR ISNULL(t.MaxTO,0) <> ISNULL(n.MaxTO,0)
					OR ISNULL(t.CPAAmount,0) <> ISNULL(n.CPAAmount,0)
			  );

			-- Add/Change: Insert new rows for added/changed
			INSERT INTO CPATierSetting (FromDate, ToDate, GroupId, GroupProductId, TierId, MinFDM, MaxFDM, MinTotalDeposit, MaxTotalDeposit, MinTO, MaxTO, CPAAmount)
			SELECT @ActionDate, @ToDate, @GroupId, n.GroupProductId, n.TierId, n.MinFDM, n.MaxFDM, n.MinTotalDeposit, n.MaxTotalDeposit, n.MinTO, n.MaxTO, n.CPAAmount
			FROM @CPATier n
			LEFT JOIN CPATierSetting t WITH (NOLOCK)
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.TierId = n.TierId
			WHERE t.GroupProductId IS NULL -- added
				OR ISNULL(t.MinFDM,0) <> ISNULL(n.MinFDM,0)
				OR ISNULL(t.MaxFDM,0) <> ISNULL(n.MaxFDM,0)
				OR ISNULL(t.MinTotalDeposit,0) <> ISNULL(n.MinTotalDeposit,0)
				OR ISNULL(t.MaxTotalDeposit,0) <> ISNULL(n.MaxTotalDeposit,0)
				OR ISNULL(t.MinTO,0) <> ISNULL(n.MinTO,0)
				OR ISNULL(t.MaxTO,0) <> ISNULL(n.MaxTO,0)
				OR ISNULL(t.CPAAmount,0) <> ISNULL(n.CPAAmount,0)
			;
		END

		-- CPAProductSetting: Add/Remove
		IF EXISTS (
			SELECT 1
			FROM (
				SELECT t.GroupProductId, t.ProductId
				FROM CPAProductSetting t WITH (NOLOCK)
				WHERE t.GroupId = @GroupId AND t.ToDate = @ToDate
			) cur
			FULL OUTER JOIN (
				SELECT n.GroupProductId, n.ProductId
				FROM @CPAProduct n
			) new
			ON cur.GroupProductId = new.GroupProductId AND cur.ProductId = new.ProductId
			WHERE cur.GroupProductId IS NULL OR new.GroupProductId IS NULL
		)
		BEGIN
			-- Old data
			INSERT INTO @old_CPAProductSetting(TypeId,FromDate,ToDate,GroupId,GroupProductId,ProductId)
			SELECT 1,FromDate,ToDate,GroupId,GroupProductId,ProductId
			FROM CPAProductSetting WITH (NOLOCK)
			WHERE GroupId = @GroupId AND ToDate = @ToDate;

			-- Remove: Update ToDate for removed
			UPDATE t
			SET ToDate = DATEADD(dd,-1,@ActionDate)
			FROM CPAProductSetting t WITH (ROWLOCK, UPDLOCK)
			LEFT JOIN @CPAProduct n
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.ProductId = n.ProductId
			WHERE t.GroupId = @GroupId AND t.ToDate = @ToDate
			  AND n.GroupProductId IS NULL;
			-- Add: Insert new rows for added
			INSERT INTO CPAProductSetting (FromDate, ToDate, GroupId, GroupProductId, ProductId)
			SELECT @ActionDate, @ToDate, @GroupId, n.GroupProductId, n.ProductId
			FROM @CPAProduct n
			LEFT JOIN CPAProductSetting t WITH (NOLOCK)
				ON t.GroupId = @GroupId AND t.ToDate = @ToDate
				AND t.GroupProductId = n.GroupProductId AND t.ProductId = n.ProductId
			WHERE t.GroupProductId IS NULL
			;
		END
	END
	-- END UPDATE

	-- =========================
	-- Write log
	-- =========================
	DECLARE @OldDealInfo NVARCHAR(MAX), @NewDealInfo NVARCHAR(MAX)
	DECLARE @OldRevenueShareInfo NVARCHAR(MAX), @NewRevenueShareInfo NVARCHAR(MAX)
	DECLARE @OldTierJson NVARCHAR(MAX), @NewTierJson NVARCHAR(MAX)
	DECLARE @OldDeductionJson NVARCHAR(MAX), @NewDeductionJson NVARCHAR(MAX)
	DECLARE @OldCPAInfo NVARCHAR(MAX), @NewCPAInfo NVARCHAR(MAX)
	DECLARE @OldCPATierJson NVARCHAR(MAX), @NewCPATierJson NVARCHAR(MAX)
	
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)

	-- 1. Deal Info (di)
	SELECT TOP 1
		@OldDealInfo = (
			SELECT 
				GroupName AS dn,
				CASE WHEN @GroupTypeId = 1 THEN 'Revenue Share' WHEN @GroupTypeId = 3 THEN 'CPA' ELSE 'Hybrid' END AS dt,
				Description AS d,
				CAST(SubCommRate AS VARCHAR(50)) AS sr
			FROM #updateData WHERE TypeId = 1
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		),
		@NewDealInfo = (
			SELECT 
				@GroupName AS dn,
				CASE WHEN @GroupTypeId = 1 THEN 'Revenue Share' WHEN @GroupTypeId = 3 THEN 'CPA' ELSE 'Hybrid' END AS dt,
				@Description AS d,
				CAST(@SubCommRate AS VARCHAR(50)) AS sr
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		)
	
	-- 2. Revenue/Hybrid (1,4)
	IF @GroupTypeId IN (1,4)
	BEGIN
		SELECT TOP 1
			@OldRevenueShareInfo = (
				SELECT 
					QMTurnover AS qpt, 
					IsActivePlayerSum AS cqp,
					(SELECT DeductedPercentage FROM #updateData WHERE TypeId = 3 AND DeductionId IN (13)) AS df,
					(SELECT DeductedAmount FROM #updateData WHERE TypeId = 3 AND DeductionId IN (13)) AS dfx,
					(SELECT DeductedPercentage FROM #updateData WHERE TypeId = 3 AND DeductionId IN (14)) AS wf,
					(SELECT DeductedAmount FROM #updateData WHERE TypeId = 3 AND DeductionId IN (14)) AS wfx
				FROM #updateData 
				WHERE TypeId = 1
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			),
			@NewRevenueShareInfo = (
				SELECT 
					@QMTurnover AS qpt,
					@IsActivePlayerSum AS cqp,
					(SELECT DeductedPercentage FROM @DeductionSetting WHERE DeductionId IN (13)) AS df,
					(SELECT DeductedAmount FROM @DeductionSetting WHERE DeductionId IN (13)) AS dfx,
					(SELECT DeductedPercentage FROM @DeductionSetting WHERE DeductionId IN (14)) AS wf,
					(SELECT DeductedAmount FROM @DeductionSetting WHERE DeductionId IN (14)) AS wfx
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			)
		-- Tier
		SET @OldTierJson = (
			SELECT 
				STRING_AGG(CAST(t1.ProductId AS VARCHAR(MAX)), ',') AS rpg,
				(SELECT TOP 1 DeductedPercentage FROM #updateData t3 WHERE t1.GroupProductId = t3.GroupProductId AND TypeId =3 AND DeductionId IN (10)) AS rf,
				(
					SELECT MinAmount AS nw, MinQM AS qp
					FROM #updateData t2 
					WHERE t2.GroupProductId = t1.GroupProductId AND t2.TypeId = 2
					FOR JSON PATH
				) AS rti
			FROM #updateData t1 
			WHERE t1.TypeId = 2
			GROUP BY GroupProductId
			FOR JSON PATH
		)
		SET @NewTierJson = (
			SELECT 
				STRING_AGG(CAST(t1.ProductId AS VARCHAR(MAX)), ',') AS rpg,
				t1.DeductedPercentage AS rf,
				(
					SELECT MinAmount AS nw, MinQM AS qp
					FROM @TierSetting t2
					WHERE t2.GroupProductId = t1.GroupProductId
					FOR JSON PATH
				) AS rti
			FROM @DeductionSetting t1
			WHERE DeductionId = 10
			GROUP BY GroupProductId,t1.DeductedPercentage
			FOR JSON PATH
		)
	END

	-- 3. CPA/Hybrid (3,4)
	IF @GroupTypeId IN (3,4)
	BEGIN
		-- CPA Info
		SELECT TOP 1
			@OldCPAInfo = (
				SELECT CountryCodes AS tc, ActiveDays AS ap, HoldingDays AS hd, HoldingTickets AS ht, Quota AS q, CASE WHEN @IsInstant = 1 THEN 'Yes' ELSE 'No' END AS ip
				FROM #updateData WHERE TypeId = 1
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			),
			@NewCPAInfo = (
				SELECT @CountryCodes AS tc, @ActiveDays AS ap, @HoldingDays AS hd, @HoldingTickets AS ht, @Quota AS q, CASE WHEN @IsInstant = 1 THEN 'Yes' ELSE 'No' END AS ip
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			)
		-- CPA Tier
		SET @OldCPATierJson = (
			SELECT STRING_AGG(CAST(ProductId AS VARCHAR(MAX)), ',') AS cpg,
				(
					SELECT MinFDM AS fd, MinTotalDeposit AS td, MinTO AS w, CPAAmount AS cpa
					FROM @old_CPATierSetting t2 WHERE t2.GroupProductId = t1.GroupProductId
					FOR JSON PATH
				) AS cti
			FROM @old_CPAProductSetting t1
			GROUP BY t1.GroupProductId
			FOR JSON PATH
		)
		SET @NewCPATierJson = (
			SELECT STRING_AGG(CAST(ProductId AS VARCHAR(MAX)), ',') AS cpg,
				(
					SELECT MinFDM AS fd, MinTotalDeposit AS td, MinTO AS w, CPAAmount AS cpa
					FROM @CPATier t2 WHERE t2.GroupProductId = t1.GroupProductId
					FOR JSON PATH
				) AS cti
			FROM @CPAProduct t1
			GROUP BY t1.GroupProductId
			FOR JSON PATH
		)
	END
	
	-- 4. Compose @OldDataJson/@NewDataJson
	DECLARE @OldData NVARCHAR(MAX) = '{'
	    + '"di":' + ISNULL(@OldDealInfo, '{}')
	    + CASE WHEN @OldCPAInfo IS NOT NULL THEN ',"ci":' + @OldCPAInfo ELSE '' END
	    + CASE WHEN @OldCPATierJson IS NOT NULL THEN ',"ct":' + @OldCPATierJson ELSE '' END
	    + CASE WHEN @OldRevenueShareInfo IS NOT NULL THEN ',"ri":' + @OldRevenueShareInfo ELSE '' END
	    + CASE WHEN @OldTierJson IS NOT NULL THEN ',"rt":' + @OldTierJson ELSE '' END
	    + '}'

	DECLARE @NewData NVARCHAR(MAX) = '{'
	    + '"di":' + ISNULL(@NewDealInfo, '{}')
	    + CASE WHEN @NewCPAInfo IS NOT NULL THEN ',"ci":' + @NewCPAInfo ELSE '' END
	    + CASE WHEN @NewCPATierJson IS NOT NULL THEN ',"ct":' + @NewCPATierJson ELSE '' END
	    + CASE WHEN @NewRevenueShareInfo IS NOT NULL THEN ',"ri":' + @NewRevenueShareInfo ELSE '' END
	    + CASE WHEN @NewTierJson IS NOT NULL THEN ',"rt":' + @NewTierJson ELSE '' END
	    + '}'

	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language,
		@Duration	= @Duration

	DROP TABLE #updateData
END
GO