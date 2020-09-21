/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Upd]
	@UserId				INT
	,@GroupId			INT
	,@GroupName			NVARCHAR(100) = NULL
	,@Description		NVARCHAR(100) = NULL
	,@DeductionList		XML
	,@TierList			XML
	,@IP				NVARCHAR(20) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin site - Add new commission group

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]

	Parameter's Explanation:
		- @DeductionList:
			<root>
				<row id="10" productids = "1,2,3" percent="0.17" amount="0" isdeductedpercent="1" />
				<row id="10" productids = "4,5" percent="0.15" amount="0" isdeductedpercent="1" />
				<row id="11" productids = "0" percent="0" amount="100" isdeductedpercent="0" />
				<row id="12" productids = "0" percent="0.02" amount="0" isdeductedpercent="1" />
			</root>
		- @TierList:
			<root>
				<row id="1" minamount="0" maxamount="100" minam="0" maxam="5" commission="0.2" />
				<row id="2" minamount="101" maxamount="100000000000000" minam="6" maxam="1000000000" commission="0.3" />
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
	SELECT ds.GroupProductId, ds.DeductionId, f.val, ISNULL(ds.DeductedPercentage, 0), ISNULL(ds.DeductedAmount, 0), ISNULL(ds.IsDeductedPercent, 0)
	FROM CTE_DeductionSetting ds
		CROSS APPLY dbo.Aff_f_StringSplit(ds.ProductIds, ',') f
	OPTION (OPTIMIZE FOR (@DeductionList = NULL), MAXRECURSION 0)

	UPDATE @DeductionSetting
	SET DeductedPercentage	= CASE WHEN IsDeductedPercent = 0 THEN 0 ELSE ISNULL(DeductedPercentage, 0) END
		,DeductedAmount		= CASE WHEN IsDeductedPercent = 1 THEN 0 ELSE ISNULL(DeductedAmount, 0) END

	-- Tier Setting
	DECLARE @TierSetting TABLE (TierID TINYINT, MinAmount MONEY, MaxAmount MONEY, MinAM INT, MaxAM INT, Commission DECIMAL(9,8))
	
	INSERT INTO @TierSetting (TierID, MinAmount, MaxAmount, MinAM, MaxAM, Commission)
	SELECT
		t.c.value('@id', 'TINYINT'),
		t.c.value('@minamount', 'MONEY'),
		t.c.value('@maxamount', 'MONEY'),
		t.c.value('@minam', 'INT'),
		t.c.value('@maxam', 'INT'),
		t.c.value('@commission', 'DECIMAL(9,8)')
	FROM @TierList.nodes('/root/row') AS t(c)
	OPTION (OPTIMIZE FOR (@TierList = NULL))

	-- Check valid tier setting
	IF (SELECT COUNT(1) FROM @TierSetting) > 50
	BEGIN
		-- Oops, maximum of 50 tiers are allowed!
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1003, @Language)

		RETURN
	END

	DECLARE @Infinity_Amount MONEY = 100000000000, @Inifinity_QM INT = 1000000000
	IF EXISTS
		(
			SELECT 1
			FROM @TierSetting ts1
				INNER JOIN @TierSetting ts2 ON ts1.TierID + 1 = ts2.TierID
			WHERE ts1.MaxAmount + 1 <> ts2.MinAmount
		)
		OR NOT EXISTS
		(
			SELECT 1 FROM @TierSetting WHERE MaxAmount = @Infinity_Amount
		)
		OR NOT EXISTS
		(
			SELECT 1 FROM @TierSetting WHERE TierId = 1 AND MinAmount = 0
		)
	BEGIN
		-- Error! Invalid Tier Setting!
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(1004, @Language)

		RETURN
	END

	DECLARE @updateData TABLE
	(
		-- 1: general, 2: tier, 3: deduction
		TypeId					TINYINT
		-- General information
		,GroupName				NVARCHAR(100)
		,Description			NVARCHAR(100)
		,IsDeductedPercent		BIT
		-- Tier List
		,TierId					TINYINT
		,MinAmount				MONEY
		,MaxAmount				MONEY
		,MinAM					INT
		,MaxAM					INT
		,Commission				DECIMAL(9,8)
		-- Deduction List
		,GroupProductId			TINYINT
		,DeductionId			TINYINT
		,ProductId				INT
		,DeductedPercentage		DECIMAL(9,8)
		,DeductedAmount			MONEY
	)

	-- General information
	BEGIN TRY
		UPDATE dbo.CommGroup WITH (ROWLOCK)
		SET GroupName = @GroupName,
			Description = @Description
		OUTPUT DELETED.GroupName,DELETED.Description,1
		INTO @updateData (GroupName,Description,TypeId)
		WHERE GroupId = @GroupId
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE cg WITH (ROWLOCK)
		SET GroupName			= up.GroupName,
			Description			= up.Description
		FROM dbo.CommGroup cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId
			AND TypeId = 1

		-- Failed to update group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1007, @Language)

		RETURN
	END CATCH

	-- Tier List
	BEGIN TRY
		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
			OUTPUT DELETED.TierId,DELETED.MinAmount,DELETED.MaxAmount,DELETED.MinAM,DELETED.MaxAM,DELETED.Commission,2
			INTO @updateData (TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission,TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT @GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT @GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM @TierSetting
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE cg WITH (ROWLOCK)
		SET GroupName			= up.GroupName,
			Description			= up.Description
		FROM dbo.CommGroup cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId
			AND TypeId = 1

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT @GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM @updateData
		WHERE TypeId = 2

		INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT @GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM @updateData
		WHERE TypeId = 2

		-- Failed to update group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1007, @Language)

		RETURN
	END CATCH

	-- Deduction List
	BEGIN TRY
		DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
			OUTPUT DELETED.DeductionId,DELETED.ProductId,DELETED.GroupProductId,DELETED.DeductedPercentage,DELETED.DeductedAmount,DELETED.IsDeductedPercent,3
			INTO @updateData (DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent,TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.DeductionSetting (GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
		SELECT @GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory(GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
		SELECT @GroupId,@MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		FROM @DeductionSetting
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE cg WITH (ROWLOCK)
		SET GroupName			= up.GroupName,
			Description			= up.Description
		FROM dbo.CommGroup cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId
			AND TypeId = 1

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT @GroupId,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM @updateData
		WHERE TypeId = 2

		INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT @GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM @updateData
		WHERE TypeId = 2

		IF NOT EXISTS (SELECT 1 FROM dbo.DeductionSetting WITH (NOLOCK) WHERE GroupId = @GroupId)
			INSERT INTO dbo.DeductionSetting (GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
			SELECT @GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
			FROM @updateData
			WHERE TypeId = 3

		IF NOT EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE GroupId = @GroupId AND MonthDate = @MonthDate)
			INSERT INTO dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
			SELECT @GroupId,@MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
			FROM @updateData
			WHERE TypeId = 3

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
				TierId		AS '@id',
				MinAmount	AS '@minamount',
				MaxAmount	AS '@maxamount',
				MinAM		AS '@minam',
				MaxAM		AS '@maxam',
				Commission	AS '@commission'
			FROM @updateData
			WHERE TypeId = 3
			FOR XML PATH('row'), ROOT('root')		
		)

	SELECT  @OldDeductionList = 
		(
			SELECT
				DeductionId			AS '@id',
				ProductIds			AS '@productids',
				DeductedPercentage	AS '@percent',
				DeductedAmount		AS '@amount',
				IsDeductedPercent	AS '@isdeductedpercent'
			FROM
			(
				SELECT
					DeductionId,
					DeductedPercentage,
					DeductedAmount,
					IsDeductedPercent,
					STUFF(
						(SELECT	',' + CONVERT(VARCHAR(10), up.ProductId)
							FROM @updateData up
							WHERE up.DeductionId = ud.DeductionId
								AND up.DeductedPercentage = ud.DeductedPercentage
								AND up.GroupProductId = ud.GroupProductId
								AND up.DeductedAmount = ud.DeductedAmount
								AND up.IsDeductedPercent = ud.IsDeductedPercent
							FOR XML PATH (''))
							, 1, 1, '') AS ProductIds
				FROM @updateData ud
				WHERE TypeId = 2
			) AS u
			FOR XML PATH('row'), ROOT('root')		
		)

	SELECT  @OldData =
		'GroupId='			+ ISNULL(CONVERT(VARCHAR(15), @GroupId), '') + ',' +
		'GroupName='		+ ISNULL(GroupName, '') + ',' +
		'Description='		+ ISNULL(Description, '') + ',' +
		'DeductionList='	+ ISNULL(CONVERT(NVARCHAR(MAX), @OldDeductionList), '') + ',' +
		'TierList='			+ ISNULL(CONVERT(NVARCHAR(MAX), @OldTierList), '')
	FROM @updateData

	SELECT  @NewData =
		'GroupId='			+ ISNULL(CONVERT(VARCHAR(15), @GroupId), '') + ',' +
		'GroupName='		+ ISNULL(@GroupName, '') + ',' +
		'Description='		+ ISNULL(@Description, '') + ',' +
		'DeductionList='	+ ISNULL(CONVERT(NVARCHAR(MAX), @DeductionList), '') + ',' +
		'TierList='			+ ISNULL(CONVERT(NVARCHAR(MAX), @TierList), '')
	
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