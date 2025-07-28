/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Ins]
	@UserId				INT
	,@GroupId			INT = 0 OUTPUT
	,@SubCommRate		DECIMAL(9,8)
	,@IsPrivate			BIT = 0
	,@GroupName			NVARCHAR(100) = ''
	,@GroupTypeId		INT = 1
	,@Description		NVARCHAR(100) = NULL
	,@DeductionList		XML = NULL
	,@TierList			XML = NULL
	,@IsActivePlayerSum BIT
	,@IP				NVARCHAR(20) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
	,@QMTurnover		MONEY
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Add new commission group

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210714@Percy: Add @StraightList for P2P Setting [RedmineID: #157958]
		- 20220307@Malcolm: Revenue Share Calculation Enhancement [RedmineId: #167335]
		- 20230404@Malcolm: Add sub commission rate [RedmineID: #185481]
		- 20240206@Sally: Merge VS 1,2,3 into VS only [RedmineID: #199895]
		- 20240425@Sally: Calculate commission by Turnover [RedmineID: #203756]
		- 20250512@Lewis: Support negative minamount, QMTurnover, IsActivePlayerSum, remove P2P [RedmineID: #226985]
		- 20250623@Sally: Enhance Revenue calculation [RedmineID: #231221]
		- 20250708@Eddie: Add new column in tier [RedmineID: #232323]

	Parameter's Explanation:
		- @DeductionList:
			<root>
				<row id="10" productids="1,2,3" percent="0.17" amount="0" isdeductedpercent="1" />
				<row id="10" productids="4,5" percent="0.15" amount="0" isdeductedpercent="1" />
				<row id="11" productids="0" percent="0" amount="100" isdeductedpercent="0" />
				<row id="12" productids="0" percent="0.02" amount="0" isdeductedpercent="1" />
				<row id="16" productids="1,2,3" percent="0.17" amount="0" isdeductedpercent="1" />
				<row id="16" productids="4,5" percent="0.15" amount="0" isdeductedpercent="1" />
			</root>
		- @TierList:
			<root>
				<row id="1" productids="1,2,3" minamount="0" maxamount="100" minam="0" maxam="5" minftdcount="1" mintotaldeposit="50" commission="0.2" />
				<row id="2" productids="1,2,3" minamount="101" maxamount="100000000000000" minam="6" maxam="1000000000" minftdcount="11" mintotaldeposit="51" commission="0.3" />
				<row id="1" productids="4,5" minamount="0" maxamount="100" minam="0" maxam="5" minftdcount="1" mintotaldeposit="50" commission="0.2" />
				<row id="2" productids="4,5" minamount="101" maxamount="100000000000000" minam="6" maxam="1000000000" minftdcount="101" mintotaldeposit="501" commission="0.3" />
			</root>
		- Note: Infinite value of MaxAmount is 100,000,000,000 and MaxAM is 1,000,000,000
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[RevenueGroup]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	-- last date of current month
	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	DECLARE @Infinity_Amount MONEY = 100000000000, @Infinity_QM INT = 1000000000
	DECLARE @Infinity_NegativeAmount MONEY = -100000000000

	SELECT @GroupName = LTRIM(RTRIM(ISNULL(@GroupName, '')))

	IF @GroupName = ''
	BEGIN
		-- Group name is invalid!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1001, @Language)
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = @GroupName AND IsDeleted = 0)
	BEGIN
		-- Group name is already existed
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(1002, @Language)

		RETURN
	END

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
	SELECT GroupProductId, ds.DeductionId, ISNULL(CONVERT(INT, f.value), 0), ISNULL(ds.DeductedPercentage, 0), ISNULL(ds.DeductedAmount, 0), ISNULL(ds.IsDeductedPercent, 0)
	FROM CTE_DeductionSetting ds
		OUTER APPLY STRING_SPLIT(dbo.Aff_f_AddRelatedProducts(ds.ProductIds), ',') f
	OPTION (OPTIMIZE FOR (@DeductionList = NULL), MAXRECURSION 0)

	UPDATE @DeductionSetting
	SET DeductedPercentage	= CASE WHEN IsDeductedPercent = 0 THEN 0 ELSE ISNULL(DeductedPercentage, 0) END
		,DeductedAmount		= CASE WHEN IsDeductedPercent = 1 THEN 0 ELSE ISNULL(DeductedAmount, 0) END

	-- Tier Setting
	DECLARE @TierSetting TABLE (TierID TINYINT, productids VARCHAR(MAX), GroupProductId TINYINT, MinAmount MONEY, MaxAmount MONEY, MinQM INT, MaxQM INT, Commission DECIMAL(9,8), IsNegativeAmount BIT, MinFTDCount INT, MaxFTDCount INT, MinTotalDeposit MONEY, MaxTotalDeposit MONEY)
	
	INSERT INTO @TierSetting (TierID, productids, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsNegativeAmount, MinFTDCount, MinTotalDeposit)
	SELECT
		t.c.value('@id', 'TINYINT'),
		t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIds,
		t.c.value('@minamount', 'MONEY'),
		t.c.value('@maxamount', 'MONEY'),
		t.c.value('@minqm', 'INT'),
		@Infinity_QM AS MaxQM,
		t.c.value('@commission', 'DECIMAL(9,8)'),
        CASE WHEN t.c.value('@minamount', 'MONEY') < 0 THEN 1 ELSE 0 END AS IsNegativeAmount,
		t.c.value('@minftdcount', 'INT'),
		t.c.value('@mintotaldeposit', 'MONEY')
	FROM @TierList.nodes('/root/row') AS t(c)
	OPTION (OPTIMIZE FOR (@TierList = NULL))

	UPDATE t	
		SET t.GroupProductId = l.GroupProductId
	FROM @TierSetting t
	CROSS APPLY (
		SELECT TOP 1 d.GroupProductId
		FROM @DeductionSetting d 
		WHERE ',' + t.productids + ',' LIKE '%,' + CONVERT(VARCHAR(20), d.ProductId) + ',%'
	) AS l

	UPDATE t1
	SET t1.MaxAmount = t2.MinAmount
	  , t1.MaxFTDCount = t2.MinFTDCount
	  , t1.MaxTotalDeposit = t2.MinTotalDeposit
	FROM @TierSetting t1
		INNER JOIN @TierSetting t2 ON t1.TierID +1 = t2.TierID AND t1.GroupProductId = t2.GroupProductId
	
	;WITH CTE AS
	(
		SELECT GroupProductId, MAX(TierID) AS TierID FROM @TierSetting GROUP BY GroupProductId
	)
	UPDATE t
	SET t.MaxAmount = @Infinity_Amount
	   ,t.MaxFTDCount = IIF(t.MinFTDCount IS NULL, t.MaxFTDCount, @Infinity_QM)
	   ,t.MaxTotalDeposit = IIF(t.MinTotalDeposit IS NULL, t.MaxTotalDeposit, @Infinity_Amount)
	FROM @TierSetting t
		INNER JOIN CTE e ON t.TierID = e.TierID AND t.GroupProductId = e.GroupProductId

	-- Check valid tier setting
    BEGIN
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
            -- 'The first Tier of the Min Net Win column must be = 0 or - infinity symbol'
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

        IF EXISTS(
				SELECT TOP 1 1
				FROM @TierSetting ts1
					INNER JOIN @TierSetting ts2 ON ts1.TierID + 1 = ts2.TierID AND ts1.GroupProductId = ts2.GroupProductId
				 WHERE ts1.MaxFTDCount > ts2.MaxFTDCount
					OR ts1.MinFTDCount > ts2.MinFTDCount
					OR ts1.MaxTotalDeposit > ts2.MaxTotalDeposit
					OR ts1.MinTotalDeposit > ts2.MinTotalDeposit
			)
        BEGIN
            SELECT @ErrCode = 204, @ErrMsg = N'Each min value of next tier must be greater than previous tier for the same group product.'
            RETURN
        END
    END

	IF @IsPrivate = 1
	BEGIN
		DECLARE @ExistsGroupId INT
		SELECT  @ExistsGroupId = GroupId FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = @GroupName AND IsPrivate = 1
		
		IF @ExistsGroupId IS NOT NULL
		BEGIN
			DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId AND MonthDate = @MonthDate

			DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId AND MonthDate = @MonthDate
		END
	END

	BEGIN TRY
		-- General information
		INSERT INTO dbo.CommGroup (GroupName, CreatedDate, Creator, IsPrivate, SubCommRate, Description, GroupTypeId, QMTurnover)
		VALUES (@GroupName, GETDATE(), @UserId, @IsPrivate, @SubCommRate, @Description, @GroupTypeId, @QMTurnover)

		SELECT @GroupId = SCOPE_IDENTITY()

		--History Group
		INSERT INTO dbo.CommGroupHistory (GroupId, MonthDate, SubCommRate, QMTurnover)
		VALUES (@GroupId, @MonthDate, @SubCommRate, @QMTurnover)

		-- Tier List
		INSERT INTO dbo.TierSetting (GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, @IsActivePlayerSum FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory (GroupId, GroupProductId, MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, @MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, @IsActivePlayerSum FROM @TierSetting

		-- Deduction List
		INSERT INTO dbo.DeductionSetting (GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, @MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.CommGroup WHERE GroupId = @GroupId
		DELETE dbo.CommGroupHistory WITH(ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId 
		DELETE dbo.TierSetting WHERE GroupId = @GroupId
		DELETE dbo.TierSettingHistory WHERE GroupId = @GroupId AND MonthDate = @MonthDate
		DELETE dbo.DeductionSetting WHERE GroupId = @GroupId
		DELETE dbo.DeductionSettingHistory WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		-- Failed to insert new group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1005, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @Data NVARCHAR(MAX)

	SELECT  @Data =
		'GroupId='		+ ISNULL(CONVERT(VARCHAR(10), @GroupId), '') + ',' +
		'GroupName='	+ ISNULL(@GroupName, '') + ',' +
		'GroupTypeId='	+ ISNULL(CONVERT(VARCHAR(10), @GroupTypeId), '') + ',' +
		'IsPrivate='	+ ISNULL(CONVERT(VARCHAR(1), @IsPrivate), '') + ',' +
		'Description='	+ ISNULL(@Description, '') + ',' +
		'DeductionList='+ ISNULL(CONVERT(NVARCHAR(MAX), @DeductionList), '') + ',' +
		'TierList='		+ ISNULL(CONVERT(NVARCHAR(MAX), @TierList), '') + ',' +
		'IsActivePlayerSum='+ ISNULL(CONVERT(NVARCHAR(MAX), @IsActivePlayerSum), '') + ',' +
		'SubCommRate='	+ ISNULL(CONVERT(NVARCHAR(MAX), @SubCommRate), '') + ',' +
		'QMTurnover='	+ ISNULL(CONVERT(NVARCHAR(MAX), @QMTurnover), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @Data,
		@IP			= @IP,
		@Language	= @Language
END
GO