/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Ins]
	@UserId			INT
	,@GroupId		INT = 0 OUTPUT
	,@IsPrivate		BIT = 0
	,@GroupName		NVARCHAR(100) = ''
	,@Description	NVARCHAR(100) = NULL
	,@DeductionList	XML
	,@TierList		XML
	,@IP			NVARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
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

	-- last date of current month
	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

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
	SELECT GroupProductId, ds.DeductionId, f.val, ISNULL(ds.DeductedPercentage, 0), ISNULL(ds.DeductedAmount, 0), ISNULL(ds.IsDeductedPercent, 0)
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

	IF @IsPrivate = 1
	BEGIN
		DECLARE @ExistsGroupId INT
		SELECT  @ExistsGroupId = GroupId FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = @GroupName AND IsPrivate = 1
		
		IF @ExistsGroupId IS NOT NULL
		BEGIN
			DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
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

	-- General information
	BEGIN TRY
		INSERT INTO dbo.CommGroup
		(
			GroupName,
			CreatedDate,
			Creator,
			IsPrivate,
			Description
		)
		VALUES
		(
			@GroupName,
			GETDATE(),
			@UserId,
			@IsPrivate,
			@Description
		)

		SELECT @GroupId = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		-- Failed to insert new group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1005, @Language)

		RETURN
	END CATCH

	-- Tier List
	BEGIN TRY
		INSERT INTO dbo.TierSetting
		(
			GroupId,
			TierId,
			MinAmount,
			MaxAmount,
			MinAM,
			MaxAM,
			Commission
		)
		SELECT
			@GroupId,
			TierId,
			MinAmount,
			MaxAmount,
			MinAM,
			MaxAM,
			Commission
		FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory
		(
			GroupId,
			MonthDate,
			TierId,
			MinAmount,
			MaxAmount,
			MinAM,
			MaxAM,
			Commission
		)
		SELECT
			@GroupId,
			@MonthDate,
			TierId,
			MinAmount,
			MaxAmount,
			MinAM,
			MaxAM,
			Commission
		FROM @TierSetting
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		-- Failed to insert new group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1005, @Language)

		RETURN
	END CATCH

	-- Deduction List
	BEGIN TRY
		INSERT INTO dbo.DeductionSetting
		(
			GroupId,
			GroupProductId,
			DeductionId,
			ProductId,
			DeductedPercentage,
			DeductedAmount,
			IsDeductedPercent
		)
		SELECT
			@GroupId,
			GroupProductId,
			DeductionId,
			ProductId,
			DeductedPercentage,
			DeductedAmount,
			IsDeductedPercent
		FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory
		(
			GroupId,
			MonthDate,
			GroupProductId,
			DeductionId,
			ProductId,
			DeductedPercentage,
			DeductedAmount,
			IsDeductedPercent
		)
		SELECT
			@GroupId,
			@MonthDate,
			GroupProductId,
			DeductionId,
			ProductId,
			DeductedPercentage,
			DeductedAmount,
			IsDeductedPercent
		FROM @DeductionSetting
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

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
		'IsPrivate='	+ ISNULL(CONVERT(VARCHAR(1), @IsPrivate), '') + ',' +
		'Description='	+ ISNULL(@Description, '') + ',' +
		'DeductionList='+ ISNULL(CONVERT(NVARCHAR(MAX), @DeductionList), '') + ',' +
		'TierList='		+ ISNULL(CONVERT(NVARCHAR(MAX), @TierList), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @Data,
		@IP			= @IP,
		@Language	= @Language
END
GO