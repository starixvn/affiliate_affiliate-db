/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Upd]
	@UserId				INT
	,@GroupId			INT
	,@GroupName			NVARCHAR(100) = NULL
	,@SubCommRate		DECIMAL(9,8)
	,@Description		NVARCHAR(100) = NULL
	,@DeductionList		XML = NULL
	,@TierList			XML = NULL
	,@QMTurnover		MONEY
	,@IsActivePlayerSum BIT
	,@IP				NVARCHAR(20) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
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
		- 20240426@Sally: Calculate Revenue Share By Turnover [RedmineID: #204177]
		- 20250512@Lewis: Support negative minamount, QMTurnover, IsActivePlayerSum [RedmineID: #226985]
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
				<row id="2" productids="1,2,3" minamount="101" maxamount="100000000000000" minam="6" maxam="1000000000" minftdcount="2" mintotaldeposit="51" commission="0.3" />
				<row id="1" productids="4,5" minamount="0" maxamount="100" minam="0" maxam="5" minftdcount="1" mintotaldeposit="50" commission="0.2" />
				<row id="2" productids="4,5" minamount="101" maxamount="100000000000000" minam="6" maxam="1000000000" minftdcount="3" mintotaldeposit="500" commission="0.3" />
			</root>
		- @StraightList:
			<root>
				<row id="1" productids="41" percent="0.16" commission="0.16" />
				<row id="2" productids="42" percent="0.17" commission="0.17" />
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

	SELECT @GroupName = LTRIM(RTRIM(ISNULL(@GroupName, '')))
	
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
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(1002, @Language)

		RETURN
	END

	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	DECLARE @Infinity_Amount MONEY = 100000000000, @Infinity_QM INT = 1000000000
	DECLARE @Infinity_NegativeAmount MONEY = -100000000000

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
		WHERE ',' + t.ProductIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), d.ProductId) + ',%'
	) AS l

	UPDATE t1
	SET t1.MaxAmount = t2.MinAmount
	  , t1.MaxFTDCount = t2.MinFTDCount
	  , t1.MaxTotalDeposit = t2.MinTotalDeposit
	FROM @TierSetting t1
		INNER JOIN @TierSetting t2 ON t1.TierID + 1 = t2.TierID AND t1.GroupProductId = t2.GroupProductId
	
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
            -- 'The first Tier of the Min Net Win column must be = 0 or - infinity symbol
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

	DECLARE @updateData TABLE
	(
		-- 1: general, 2: tier, 3: deduction
		TypeId					TINYINT
		-- General information
		,SubCommRate			DECIMAL(9,8)
		,GroupName				NVARCHAR(100)
		,Description			NVARCHAR(100)
		,IsDeductedPercent		BIT
		,QMTurnover				MONEY
		-- Tier List
		,TierId					TINYINT
		,MinAmount				MONEY
		,MaxAmount				MONEY
		,MinQM					INT
		,MaxQM					INT
		,MinFTDCount 			INT
		,MaxFTDCount 			INT
		,MinTotalDeposit 		MONEY
		,MaxTotalDeposit 		MONEY
		,Commission				DECIMAL(9, 8)
		,IsActivePlayerSum		BIT
		-- Deduction List
		,GroupProductId			TINYINT
		,DeductionId			TINYINT
		,ProductId				INT
		,DeductedPercentage		DECIMAL(9, 8)
		,DeductedAmount			MONEY
	)

	BEGIN TRY
		-- General information
		UPDATE dbo.CommGroup WITH (ROWLOCK)
		SET GroupName = @GroupName, Description = @Description, SubCommRate = @SubCommRate, QMTurnover = @QMTurnover
			OUTPUT DELETED.GroupName, DELETED.SubCommRate, DELETED.Description, DELETED.QMTurnover, 1
			INTO @updateData (GroupName, SubCommRate, Description, QMTurnover, TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.CommGroupHistory WITH(ROWLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.CommGroupHistory (GroupId, MonthDate, SubCommRate, QMTurnover)
		SELECT @GroupId, @MonthDate, @SubCommRate, @QMTurnover

		-- Tier List
		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
			OUTPUT DELETED.TierId, DELETED.GroupProductId, DELETED.MinAmount, DELETED.MaxAmount, DELETED.MinQM, DELETED.MaxQM, DELETED.MinFTDCount, DELETED.MaxFTDCount, DELETED.MinTotalDeposit, DELETED.MaxTotalDeposit, DELETED.Commission, DELETED.IsActivePlayerSum, 2
			INTO @updateData (TierId, GroupProductId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum, TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, @IsActivePlayerSum FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory (GroupId, GroupProductId, MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, @MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, @IsActivePlayerSum FROM @TierSetting

		-- Deduction List
		DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
			OUTPUT DELETED.DeductionId, DELETED.ProductId, DELETED.GroupProductId, DELETED.DeductedPercentage, DELETED.DeductedAmount, DELETED.IsDeductedPercent, 3
			INTO @updateData (DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent, TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.DeductionSetting (GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, @MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

	END TRY
	BEGIN CATCH
		-- Rollback manually
		IF EXISTS (SELECT 1 FROM @updateData WHERE TypeId = 1)
		BEGIN
			UPDATE cg WITH (ROWLOCK)
			SET GroupName		= up.GroupName,
				Description		= up.Description,
				cg.SubCommRate	= up.SubCommRate,
				cg.QMTurnover	= up.QMTurnover
			FROM dbo.CommGroup cg
				CROSS APPLY @updateData up
			WHERE cg.GroupId = @GroupId
				AND TypeId = 1

			DELETE dbo.CommGroupHistory WITH(ROWLOCK, UPDLOCK) 
			WHERE GroupId = @GroupId AND MonthDate = @MonthDate

			INSERT INTO dbo.CommGroupHistory (GroupId, SubCommRate, MonthDate, QMTurnover)
			SELECT @GroupId, SubCommRate, @MonthDate, QMTurnover FROM @updateData WHERE TypeId = 1
		END

		IF EXISTS (SELECT 1 FROM @updateData WHERE TypeId = 2)
		BEGIN
			DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId
			DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

			INSERT INTO dbo.TierSetting (GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum)
			SELECT @GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum FROM @updateData WHERE TypeId = 2

			INSERT INTO dbo.TierSettingHistory (GroupId, GroupProductId, MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum)
			SELECT @GroupId, GroupProductId, @MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, MinFTDCount, MaxFTDCount, MinTotalDeposit, MaxTotalDeposit, Commission, IsActivePlayerSum FROM @updateData WHERE TypeId = 2
		END

		IF EXISTS (SELECT 1 FROM @updateData WHERE TypeId = 3)
		BEGIN
			DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId
			DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate

			INSERT INTO dbo.DeductionSetting (GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
			SELECT @GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @updateData WHERE TypeId = 3
			
			INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
			SELECT @GroupId, @MonthDate,GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @updateData WHERE TypeId = 3
		END

		-- Failed to update group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1007, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	DECLARE @OldDeductionList XML, @OldTierList XML

	SELECT  @OldTierList = 
		(
			SELECT
				u.TierId			AS '@id',
				u.MinAmount			AS '@minamount',
				u.MaxAmount			AS '@maxamount',
				u.MinQM				AS '@minqm',
				u.MaxQM				AS '@maxqm',
				u.MinFTDCount		AS '@minftdcount',
				u.MinTotalDeposit	AS '@mintotaldeposit',
				u.Commission		AS '@commission',
				u.GroupProductId	AS '@GroupProductId',
				u.IsActivePlayerSum AS '@IsActivePlayerSum',
				l.productids		AS '@productids'
			FROM @updateData u
				CROSS APPLY (
					SELECT STUFF
						   (
								(
									SELECT ',' + CONVERT(VARCHAR(20), d.ProductId) AS productids
									FROM @updateData d
									WHERE u.GroupProductId = d.GroupProductId AND d.DeductionId = 10 AND d.TypeId = 3
									FOR XML PATH ('')
								 ), 1, 1, '')
				 ) AS l (productids)
			 WHERE u.TypeId = 2
			 FOR XML PATH('row'), ROOT('root')		
		)

	SELECT  @OldDeductionList = 
		(
			SELECT
				DeductionId			AS '@id',
				ProductIds			AS '@productids',
				DeductedPercentage	AS '@percent',
				DeductedAmount		AS '@amount',
				IsDeductedPercent	AS '@isdeductedpercent',
				GroupProductId      AS '@GroupProductId'
			FROM
			(
				SELECT
					ud.DeductionId,
					ud.DeductedPercentage,
					ud.DeductedAmount,
					ud.IsDeductedPercent,
					STUFF(
						(SELECT	',' + CONVERT(VARCHAR(10), up.ProductId)
							FROM @updateData up
							WHERE up.DeductionId = ud.DeductionId
								AND up.DeductedPercentage = ud.DeductedPercentage
								AND up.GroupProductId = ud.GroupProductId
								AND up.DeductedAmount = ud.DeductedAmount
								AND up.IsDeductedPercent = ud.IsDeductedPercent
								AND up.TypeId = ud.TypeId
							FOR XML PATH (''))
							, 1, 1, '') AS ProductIds,
					ud.GroupProductId
				FROM @updateData ud
				WHERE ud.TypeId = 3
			) AS u
			FOR XML PATH('row'), ROOT('root')		
		)

	SELECT  @OldData =
		'GroupId='			+ ISNULL(CONVERT(VARCHAR(15), @GroupId), '') + ',' +
		'GroupName='		+ ISNULL(GroupName, '') + ',' +
		'Description='		+ ISNULL(Description, '') + ',' +
		'SubCommRate='		+ ISNULL(CONVERT(VARCHAR(15), SubCommRate), '') + ',' +
		'QMTurnover='		+ ISNULL(CONVERT(VARCHAR(15), QMTurnover), '') + ',' +
		'DeductionList='	+ ISNULL(CONVERT(NVARCHAR(MAX), @OldDeductionList), '') + ',' +
		'TierList='			+ ISNULL(CONVERT(NVARCHAR(MAX), @OldTierList), '')
	FROM @updateData WHERE TypeId = 1

	SELECT  @NewData =
		'GroupId='			+ ISNULL(CONVERT(VARCHAR(15), @GroupId), '') + ',' +
		'GroupName='		+ ISNULL(@GroupName, '') + ',' +
		'Description='		+ ISNULL(@Description, '') + ',' +
		'SubCommRate='		+ ISNULL(CONVERT(VARCHAR(15), @SubCommRate), '') + ',' +
		'QMTurnover='		+ ISNULL(CONVERT(VARCHAR(15), @QMTurnover), '') + ',' +
		'DeductionList='	+ ISNULL(CONVERT(NVARCHAR(MAX), @DeductionList), '') + ',' +
		'TierList='			+ ISNULL(CONVERT(NVARCHAR(MAX), @TierList), '') + ',' +
		'IsActivePlayerSum='+ ISNULL(CONVERT(NVARCHAR(MAX), @IsActivePlayerSum), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO